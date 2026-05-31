import Combine
import Foundation

/// Manages persistent storage for bookmarked vocabulary words and dictionary entries.
///
/// WHAT IT DOES:
/// - Holds two collections: savedDictionaryEntries and savedVocabularyWords.
/// - Both are persisted to UserDefaults so they survive app restarts.
/// - Provides isSaved() checks and toggleSaved() methods used by UI buttons.
///
/// WHEN IT SHOWS:
/// - ToggleSaveButton in DictionaryView calls isSaved()/toggleSaved() for each entry shown.
/// - VocabularyView calls isSaved(word:)/toggleSaved(word:) when the user taps the bookmark icon.
/// - Both components are @EnvironmentObject-injected from EngifyApp.
///
/// HOW IT WORKS:
/// - On init, loadSavedData() reads from UserDefaults and reconstructs the collections.
/// - On every mutation, saveSavedData() immediately writes back to UserDefaults.
/// - DictionaryEntry uses word.lowercased() as its id; vocabulary words are stored as a Set of lowercase strings.
@MainActor
final class SavedWordsManager: ObservableObject {
    @Published private(set) var savedDictionaryEntries: [DictionaryEntry] = []
    @Published private(set) var savedWords: [Word] = []
    @Published private(set) var lastSavedWordEvent: SavedWordEvent?

    private let dictionaryStorageKey = "engify.saved.dictionary.entries"
    private let savedWordsStorageKey = "engify.saved.words"
    private let supabaseManager: SupabaseManager
    private var currentUserID: String?
    private var isApplyingRemoteState = false

    init(supabaseManager: SupabaseManager = .shared) {
        self.supabaseManager = supabaseManager
        loadSavedData()
    }

    func isSaved(_ entry: DictionaryEntry) -> Bool {
        let normalizedWord = entry.word.lowercased()
        return savedDictionaryEntries.contains { $0.word.lowercased() == normalizedWord }
            || savedWords.contains { $0.word.lowercased() == normalizedWord }
    }

    func toggleSaved(_ entry: DictionaryEntry) {
        let normalizedWord = entry.word.lowercased()

        if isSaved(entry) {
            removeSavedWord(named: normalizedWord)
        } else {
            savedDictionaryEntries.append(entry)
            lastSavedWordEvent = .dictionary(entry)
            syncSavedWordToRemote(
                Word(
                    word: entry.word,
                    pronunciation: entry.phonetic,
                    partOfSpeech: entry.partOfSpeech,
                    meaning: entry.vietnameseMeaning,
                    example: entry.example,
                    source: .vocabulary
                )
            )
        }

        saveSavedData()
    }

    func isSaved(word: Word) -> Bool {
        let normalizedWord = word.word.lowercased()
        return savedWords.contains { $0.word.lowercased() == normalizedWord }
            || savedDictionaryEntries.contains { $0.word.lowercased() == normalizedWord }
    }

    func toggleSaved(word: Word) {
        let normalizedWord = word.word.lowercased()

        if isSaved(word: word) {
            removeSavedWord(named: normalizedWord)
        } else {
            savedWords.append(word)
            lastSavedWordEvent = .vocabulary(word)
            syncSavedWordToRemote(word)
        }

        saveSavedData()
    }

    var savedWordBankItems: [SavedWordBankItem] {
        let dictionaryItems = savedDictionaryEntries.map { entry in
            SavedWordBankItem(
                id: "dictionary:\(entry.id)",
                title: entry.word,
                subtitle: entry.partOfSpeech.capitalized,
                phonetic: entry.phonetic,
                detail: entry.vietnameseMeaning,
                example: entry.example,
                source: .dictionary,
                createdAt: nil
            )
        }

        let vocabularyItems: [SavedWordBankItem] = savedWords.map { word in
            SavedWordBankItem(
                id: "\(word.source.rawValue):\(word.word.lowercased())",
                title: word.word,
                subtitle: word.partOfSpeech.capitalized,
                phonetic: word.pronunciation,
                detail: word.meaning,
                example: word.example,
                source: word.source == .news ? .news : .vocabulary,
                createdAt: nil
            )
        }

        var dedupedItems: [SavedWordBankItem] = []
        var seenWords = Set<String>()

        for item in dictionaryItems + vocabularyItems {
            let normalizedTitle = item.title.lowercased()
            guard !seenWords.contains(normalizedTitle) else { continue }
            seenWords.insert(normalizedTitle)
            dedupedItems.append(item)
        }

        return dedupedItems.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func consumeLastSavedWordEvent() -> SavedWordEvent? {
        let event = lastSavedWordEvent
        lastSavedWordEvent = nil
        return event
    }

    func loadFromRemote(for userID: String) async {
        currentUserID = userID

        do {
            let remoteWords = try await supabaseManager.fetchSavedWords(userId: userID)
            isApplyingRemoteState = true
            savedDictionaryEntries = []
            savedWords = remoteWords
            saveSavedData()
            isApplyingRemoteState = false
        } catch {
            print("Failed to load saved words: \(error.localizedDescription)")
        }
    }

    func clearRemoteSession() {
        currentUserID = nil
    }

    private func loadSavedData() {
        if let dictionaryData = UserDefaults.standard.data(forKey: dictionaryStorageKey),
           let decodedEntries = try? JSONDecoder().decode([DictionaryEntry].self, from: dictionaryData) {
            savedDictionaryEntries = decodedEntries
        }

        if let wordsData = UserDefaults.standard.data(forKey: savedWordsStorageKey),
           let decodedWords = try? JSONDecoder().decode([Word].self, from: wordsData) {
            savedWords = decodedWords
        } else if let legacyVocabularyArray = UserDefaults.standard.array(forKey: "engify.saved.vocabulary.words") as? [String] {
            let vocabularyLookup = Dictionary(uniqueKeysWithValues: EngifySampleData.vocabularyWords.map { ($0.word.lowercased(), $0) })
            savedWords = legacyVocabularyArray.compactMap { vocabularyLookup[$0.lowercased()] }
        }
    }

    private func saveSavedData() {
        if let encodedDictionary = try? JSONEncoder().encode(savedDictionaryEntries) {
            UserDefaults.standard.set(encodedDictionary, forKey: dictionaryStorageKey)
        }

        if let encodedWords = try? JSONEncoder().encode(savedWords) {
            UserDefaults.standard.set(encodedWords, forKey: savedWordsStorageKey)
        }
    }

    private func removeSavedWord(named normalizedWord: String) {
        let removedWord = savedWords.first { $0.word.lowercased() == normalizedWord }
            ?? savedDictionaryEntries.first { $0.word.lowercased() == normalizedWord }.map {
                Word(
                    word: $0.word,
                    pronunciation: $0.phonetic,
                    partOfSpeech: $0.partOfSpeech,
                    meaning: $0.vietnameseMeaning,
                    example: $0.example,
                    source: .vocabulary
                )
            }

        savedDictionaryEntries.removeAll { $0.word.lowercased() == normalizedWord }
        savedWords.removeAll { $0.word.lowercased() == normalizedWord }

        guard let removedWord else { return }
        deleteSavedWordFromRemote(removedWord)
    }

    private func syncSavedWordToRemote(_ word: Word) {
        guard currentUserID != nil, !isApplyingRemoteState else { return }

        Task {
            do {
                try await supabaseManager.saveWord(word)
            } catch {
                print("Failed to save word remotely: \(error.localizedDescription)")
            }
        }
    }

    private func deleteSavedWordFromRemote(_ word: Word) {
        guard let currentUserID, !isApplyingRemoteState else { return }

        Task {
            do {
                try await supabaseManager.deleteSavedWord(
                    userId: currentUserID,
                    wordId: word.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                )
            } catch {
                print("Failed to delete saved word remotely: \(error.localizedDescription)")
            }
        }
    }
}

enum SavedWordEvent: Equatable {
    case dictionary(DictionaryEntry)
    case vocabulary(Word)

    var displayTitle: String {
        switch self {
        case let .dictionary(entry):
            return entry.word
        case let .vocabulary(word):
            return word.word
        }
    }
}

struct SavedWordBankItem: Identifiable, Equatable {
    enum Source: Equatable {
        case dictionary
        case vocabulary
        case news

        var label: String {
            switch self {
            case .dictionary:
                return "Dictionary"
            case .vocabulary:
                return "Vocabulary"
            case .news:
                return "News"
            }
        }
    }

    let id: String
    let title: String
    let subtitle: String
    let phonetic: String
    let detail: String
    let example: String
    let source: Source
    let createdAt: Date?
}
