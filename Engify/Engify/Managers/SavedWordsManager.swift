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
        }

        saveSavedData()
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
