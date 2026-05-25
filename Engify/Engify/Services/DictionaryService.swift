import Foundation

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
    private static let defaultLookupBaseURL = "https://api.dictionaryapi.dev/api/v2/entries/en"
    private static let dictionaryAPISettingsKey = "engify.settings.dictionary_api_base_url"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchWord(_ word: String) async throws -> DictionaryEntry {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedWord.isEmpty else {
            throw DictionaryServiceError.emptyQuery
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
            phonetic: phonetic.nonEmpty ?? "N/A",
            audioURL: audioURL,
            partOfSpeech: meaning?.partOfSpeech.nonEmpty ?? "N/A",
            definition: definition?.definition.nonEmpty ?? "N/A",
            example: definition?.example?.nonEmpty ?? "N/A",
            vietnameseMeaning: "N/A",
            nounForm: "N/A",
            adjectiveForm: "N/A",
            verbForm: "N/A"
        )
    }

    func suggestWords(for query: String) async throws -> [DictionarySuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else {
            return []
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

    private func resolvedLookupBaseURL() -> String {
        let configured = UserDefaults.standard.string(forKey: Self.dictionaryAPISettingsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let configured, !configured.isEmpty, URL(string: configured) != nil else {
            return Self.defaultLookupBaseURL
        }

        return configured.hasSuffix("/") ? String(configured.dropLast()) : configured
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

private extension String {
    var nonEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
