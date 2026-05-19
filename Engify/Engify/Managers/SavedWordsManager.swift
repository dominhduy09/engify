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
    @Published private(set) var savedVocabularyWords: Set<String> = []
    @Published private(set) var lastSavedWordEvent: SavedWordEvent?

    private let dictionaryStorageKey = "engify.saved.dictionary.entries"
    private let vocabularyStorageKey = "engify.saved.vocabulary.words"

    init() {
        loadSavedData()
    }

    func isSaved(_ entry: DictionaryEntry) -> Bool {
        savedDictionaryEntries.contains(entry)
    }

    func toggleSaved(_ entry: DictionaryEntry) {
        if isSaved(entry) {
            for i in savedDictionaryEntries.indices.reversed() {
                if savedDictionaryEntries[i].id == entry.id {
                    savedDictionaryEntries.remove(at: i)
                    break
                }
            }
        } else {
            savedDictionaryEntries.append(entry)
            lastSavedWordEvent = .dictionary(entry)
        }

        saveSavedData()
    }

    func isSaved(word: Word) -> Bool {
        savedVocabularyWords.contains(word.word.lowercased())
    }

    func toggleSaved(word: Word) {
        let key = word.word.lowercased()
        if savedVocabularyWords.contains(key) {
            savedVocabularyWords.remove(key)
        } else {
            savedVocabularyWords.insert(key)
            lastSavedWordEvent = .vocabulary(word)
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

        let vocabularyItems: [SavedWordBankItem] = EngifySampleData.vocabularyWords.compactMap { word -> SavedWordBankItem? in
            guard savedVocabularyWords.contains(word.word.lowercased()) else { return nil }

            return SavedWordBankItem(
                id: "vocabulary:\(word.word.lowercased())",
                title: word.word,
                subtitle: word.partOfSpeech.capitalized,
                phonetic: word.pronunciation,
                detail: word.meaning,
                example: word.example,
                source: .vocabulary,
                createdAt: nil
            )
        }

        return dictionaryItems + vocabularyItems.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func consumeLastSavedWordEvent() -> SavedWordEvent? {
        let event = lastSavedWordEvent
        lastSavedWordEvent = nil
        return event
    }

    private func loadSavedData() {
        if let dictionaryData = UserDefaults.standard.data(forKey: dictionaryStorageKey),
           let decodedEntries = try? JSONDecoder().decode([DictionaryEntry].self, from: dictionaryData) {
            savedDictionaryEntries = decodedEntries
        }

        if let vocabularyArray = UserDefaults.standard.array(forKey: vocabularyStorageKey) as? [String] {
            savedVocabularyWords = Set(vocabularyArray)
        }
    }

    private func saveSavedData() {
        if let encodedDictionary = try? JSONEncoder().encode(savedDictionaryEntries) {
            UserDefaults.standard.set(encodedDictionary, forKey: dictionaryStorageKey)
        }

        UserDefaults.standard.set(Array(savedVocabularyWords), forKey: vocabularyStorageKey)
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

        var label: String {
            switch self {
            case .dictionary:
                return "Dictionary"
            case .vocabulary:
                return "Vocabulary"
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
