import Foundation
import Supabase

/// Network service for dictionary lookups and spelling suggestions.
///
/// WHAT IT DOES:
/// - searchWord(): calls dictionaryapi.dev to get definitions, phonetics, audio URL,
///   part of speech, and example for a given English word.
/// - suggestWords(): calls datamuse.com/sug for real-time spelling suggestions as the user types.
///
/// WHEN IT SHOWS:
/// - Called by DictionaryViewModel on search submit (searchWord) and on debounced
///   text change while typing (suggestWords).
/// - This is the only network layer for the Dictionary tab; no local caching.
///
/// HOW IT WORKS:
/// - Both methods are async and throw on network/parse errors.
/// - searchWord() decodes the dictionaryapi.dev JSON response into a DictionaryEntry.
///   The vietnameseMeaning field is placeholder text ("Tạm dịch: [word]").
/// - suggestWords() decodes Datamuse results, maps them to DictionarySuggestion with
///   the first tag as the hint string.
struct DictionaryService {
    private let session: URLSession
    private let supabaseProvider: SupabaseClientProvider
    private static let defaultLookupBaseURL = "https://api.dictionaryapi.dev/api/v2/entries/en"
    private static let datamuseWordsBaseURL = "https://api.datamuse.com/words"
    private static let dictionaryAPISettingsKey = "engify.settings.dictionary_api_base_url"
    private static let vocabularyTopics = [
        "learning",
        "education",
        "travel",
        "technology",
        "work",
        "health",
        "culture",
        "conversation"
    ]
    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyz")

    init(session: URLSession = .shared, supabaseProvider: SupabaseClientProvider = .shared) {
        self.session = session
        self.supabaseProvider = supabaseProvider
    }

    func searchWord(_ word: String) async throws -> DictionaryEntry {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedWord.isEmpty else {
            throw DictionaryServiceError.emptyQuery
        }

        if let remoteEntry = try await fetchSupabaseWord(trimmedWord) {
            return remoteEntry
        }

        let urlString = "\(resolvedLookupBaseURL())/\(trimmedWord)"
        guard let url = URL(string: urlString) else {
            throw DictionaryServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw DictionaryServiceError.wordNotFound
        }

        let entries = try JSONDecoder().decode([DictionaryAPIResponse].self, from: data)
        guard let first = entries.first else {
            throw DictionaryServiceError.wordNotFound
        }

        let meaning = first.meanings.first
        let definition = meaning?.definitions.first
        let phonetic = first.phonetic ?? first.phonetics.compactMap { $0.text }.first ?? ""
        let audioURL = first.phonetics.compactMap { $0.audio.flatMap { URL(string: $0) } }.first
        return DictionaryEntry(
            word: first.word,
            category: "General",
            wordLevel: "N/A",
            phonetic: phonetic.nonEmpty ?? "N/A",
            audioURL: audioURL,
            partOfSpeech: meaning?.partOfSpeech.nonEmpty ?? "N/A",
            definition: definition?.definition.nonEmpty ?? "N/A",
            example: definition?.example?.nonEmpty ?? "N/A",
            vietnameseMeaning: "N/A",
            nounForm: "N/A",
            adjectiveForm: "N/A",
            verbForm: "N/A",
            idiom: "N/A",
            phrasalVerbs: []
        )
    }

    func suggestWords(for query: String) async throws -> [DictionarySuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else {
            return []
        }

        if let suggestions = try await fetchSupabaseSuggestions(query: trimmedQuery),
           !suggestions.isEmpty {
            return suggestions
        }

        var components = URLComponents(string: "https://api.datamuse.com/sug")
        components?.queryItems = [URLQueryItem(name: "s", value: trimmedQuery)]

        guard let url = components?.url else {
            throw DictionaryServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            return []
        }

        let results = try JSONDecoder().decode([DatamuseSuggestionResponse].self, from: data)
        return results.map { response in
            DictionarySuggestion(word: response.word, hint: response.tags?.first)
        }
    }

    func fetchRandomWordBatch(limit: Int = 24, allowedWordLevels: Set<String>? = nil) async throws -> [String] {
        if let remoteWords = try await fetchSupabaseWordBatch(limit: max(limit * 3, limit)),
           !remoteWords.isEmpty {
            let resolvedRemoteWords = remoteWords.filter { word in
                guard let allowedWordLevels else { return true }
                return allowedWordLevels.contains(word.wordLevel.uppercased())
            }

            let candidateWords = resolvedRemoteWords.isEmpty ? remoteWords : resolvedRemoteWords
            let normalizedWords = candidateWords.compactMap { result -> String? in
                let normalized = result.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard Self.isSupportedLessonWord(normalized) else { return nil }
                return normalized
            }

            return Array(
                NSOrderedSet(array: normalizedWords.shuffled())
                    .compactMap { $0 as? String }
                    .prefix(limit)
            )
        }

        var components = URLComponents(string: Self.datamuseWordsBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "sp", value: Self.randomWildcardPattern()),
            URLQueryItem(name: "topics", value: Self.vocabularyTopics.randomElement() ?? "learning"),
            URLQueryItem(name: "md", value: "p"),
            URLQueryItem(name: "max", value: String(max(limit * 3, limit)))
        ]

        guard let url = components?.url else {
            throw DictionaryServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw DictionaryServiceError.wordNotFound
        }

        let results = try JSONDecoder().decode([DatamuseWordResponse].self, from: data)
        let words = results.compactMap { result -> String? in
            let normalized = result.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard Self.isSupportedLessonWord(normalized) else { return nil }
            guard result.tags?.contains(where: Self.isSupportedPartOfSpeechTag) ?? true else { return nil }
            return normalized
        }

        return Array(
            NSOrderedSet(array: words)
                .compactMap { $0 as? String }
                .prefix(limit)
        )
    }

    private func resolvedLookupBaseURL() -> String {
        let configured = UserDefaults.standard.string(forKey: Self.dictionaryAPISettingsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let configured, !configured.isEmpty, URL(string: configured) != nil else {
            return Self.defaultLookupBaseURL
        }

        return configured.hasSuffix("/") ? String(configured.dropLast()) : configured
    }

    private static func randomWildcardPattern() -> String {
        let prefixLength = Bool.random() ? 1 : 2
        let prefix = String((0..<prefixLength).compactMap { _ in alphabet.randomElement() })
        return prefix + (Bool.random() ? "*" : "?*")
    }

    private static func isSupportedLessonWord(_ word: String) -> Bool {
        guard (4...12).contains(word.count) else { return false }
        return word.unicodeScalars.allSatisfy(CharacterSet.letters.contains)
    }

    private static func isSupportedPartOfSpeechTag(_ tag: String) -> Bool {
        ["n", "v", "adj", "adv"].contains(tag)
    }

    private func fetchSupabaseWord(_ word: String) async throws -> DictionaryEntry? {
        guard let client = supabaseProvider.client else { return nil }

        let response: PostgrestResponse<[SupabaseVocabularyWord]> = try await client
            .from("vocabulary_words")
            .select()
            .ilike("word", pattern: word)
            .limit(1)
            .execute()

        return response.value.first?.asDictionaryEntry
    }

    private func fetchSupabaseSuggestions(query: String) async throws -> [DictionarySuggestion]? {
        guard let client = supabaseProvider.client else { return nil }

        let response: PostgrestResponse<[SupabaseVocabularyWord]> = try await client
            .from("vocabulary_words")
            .select()
            .ilike("word", pattern: "\(query)%")
            .order("word", ascending: true)
            .limit(8)
            .execute()

        return response.value.map {
            DictionarySuggestion(word: $0.word, hint: "\($0.partOfSpeech) • \($0.wordLevel)")
        }
    }

    private func fetchSupabaseWordBatch(limit: Int) async throws -> [SupabaseVocabularyWord]? {
        guard let client = supabaseProvider.client else { return nil }

        let response: PostgrestResponse<[SupabaseVocabularyWord]> = try await client
            .from("vocabulary_words")
            .select()
            .order("is_featured", ascending: false)
            .order("word", ascending: true)
            .limit(max(limit, 24))
            .execute()

        return response.value
    }
}

enum DictionaryServiceError: LocalizedError {
    case emptyQuery
    case invalidURL
    case wordNotFound

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Please type a word to search."
        case .invalidURL:
            return "The search URL could not be created."
        case .wordNotFound:
            return "Word not found. Try another word."
        }
    }
}

private struct DictionaryAPIResponse: Decodable {
    let word: String
    let phonetic: String?
    let phonetics: [DictionaryPhonetic]
    let meanings: [DictionaryMeaning]
}

private struct DictionaryPhonetic: Decodable {
    let text: String?
    let audio: String?
}

private struct DictionaryMeaning: Decodable {
    let partOfSpeech: String
    let definitions: [DictionaryDefinition]
}

private struct DictionaryDefinition: Decodable {
    let definition: String
    let example: String?
}

private struct DatamuseSuggestionResponse: Decodable {
    let word: String
    let score: Int?
    let tags: [String]?
}

private struct DatamuseWordResponse: Decodable {
    let word: String
    let score: Int?
    let tags: [String]?
}

struct SupabaseVocabularyWord: Codable {
    let word: String
    let category: String
    let wordLevel: String
    let pronunciation: String
    let audioURL: String?
    let partOfSpeech: String
    let definition: String
    let vietnameseMeaning: String
    let example: String
    let nounForm: String
    let adjectiveForm: String
    let verbForm: String
    let idiom: String
    let phrasalVerbs: [String]

    enum CodingKeys: String, CodingKey {
        case word
        case category
        case wordLevel = "word_level"
        case pronunciation
        case audioURL = "audio_url"
        case partOfSpeech = "part_of_speech"
        case definition
        case vietnameseMeaning = "vietnamese_meaning"
        case example
        case nounForm = "noun_form"
        case adjectiveForm = "adjective_form"
        case verbForm = "verb_form"
        case idiom
        case phrasalVerbs = "phrasal_verbs"
    }

    var asDictionaryEntry: DictionaryEntry {
        DictionaryEntry(
            word: word,
            category: category,
            wordLevel: wordLevel,
            phonetic: pronunciation,
            audioURL: audioURL.flatMap { URL(string: $0) },
            partOfSpeech: partOfSpeech,
            definition: definition,
            example: example,
            vietnameseMeaning: vietnameseMeaning,
            nounForm: nounForm,
            adjectiveForm: adjectiveForm,
            verbForm: verbForm,
            idiom: idiom,
            phrasalVerbs: phrasalVerbs
        )
    }
}

private extension String {
    var nonEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
