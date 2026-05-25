import Combine
import Foundation

/// ViewModel bridging DictionaryView UI and DictionaryService data layer.
///
/// WHAT IT DOES:
/// - Manages all state for the Dictionary tab: search text, loading flags, suggestions list,
///   the current word entry result, error message, and recent search history.
/// - Debounces the search text to avoid calling the API on every keystroke.
/// - Tracks recent searches in UserDefaults (up to 8 entries).
///
/// WHEN IT SHOWS:
/// - Active only while the Dictionary tab is open and the search bar is focused.
/// - Drives the suggestion dropdown, the entry result card, and the empty/loading/error states.
///
/// HOW IT WORKS:
/// - bindSearchText() subscribes to $searchText with a 300ms debounce, then calls fetchSuggestions().
/// - search() (called on submit) calls DictionaryService.searchWord() and adds to recent searches.
/// - selectSuggestion() sets a flag to suppress the next suggestion fetch (avoids flickering).
@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var currentEntry: DictionaryEntry?
    @Published var isLoading = false
    @Published var isSuggestionsLoading = false
    @Published var suggestions: [DictionarySuggestion] = []
    @Published var recentSearches: [String] = []
    @Published var errorMessage: String?
    @Published var showSuggestions = false

    private let service: DictionaryService
    private let recentSearchesKey = "engify.dictionary.recent-searches"
    private let lastSearchTextKey = "engify.dictionary.last-search-text"
    private let lastEntryKey = "engify.dictionary.last-entry"
    private let persistLookupState: Bool
    private var cancellables = Set<AnyCancellable>()
    private var suppressNextSuggestionFetch = false

    init(service: DictionaryService? = nil, persistLookupState: Bool = false) {
        self.service = service ?? DictionaryService()
        self.persistLookupState = persistLookupState
        loadRecentSearches()
        restorePersistedStateIfNeeded()
        bindSearchText()
    }

    func search() async {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            currentEntry = nil
            errorMessage = "Please enter a word to search."
            persistStateIfNeeded()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            currentEntry = try await service.searchWord(trimmedText)
            addRecentSearch(trimmedText)
        } catch {
            currentEntry = DictionaryEntry.placeholder(for: trimmedText)
            errorMessage = nil
        }

        isLoading = false
        persistStateIfNeeded()
    }

    func selectSuggestion(_ suggestion: DictionarySuggestion) {
        suppressNextSuggestionFetch = true
        searchText = suggestion.word
        suggestions = []
        showSuggestions = false
        Task { await search() }
    }

    func runSearch(for text: String) {
        suppressNextSuggestionFetch = true
        searchText = text
        Task { await search() }
    }

    func clearSearch() {
        searchText = ""
        currentEntry = nil
        errorMessage = nil
        suggestions = []
        showSuggestions = false
        persistStateIfNeeded()
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }

    func removeRecentSearch(_ query: String) {
        let normalized = query.lowercased()
        recentSearches.removeAll { $0.lowercased() == normalized }
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }

    private func bindSearchText() {
        $searchText
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self else { return }
                if self.suppressNextSuggestionFetch {
                    self.suppressNextSuggestionFetch = false
                    return
                }
                Task { await self.fetchSuggestions(for: text) }
            }
            .store(in: &cancellables)
    }

    private var activeSuggestionTask: Task<Void, Never>?

    private func fetchSuggestions(for query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 1 else {
            suggestions = []
            showSuggestions = false
            isSuggestionsLoading = false
            return
        }

        // Cancel any in-flight suggestion request to avoid stale results
        activeSuggestionTask?.cancel()

        let task = Task {
            isSuggestionsLoading = true

            do {
                let results = try await service.suggestWords(for: trimmed)
                guard !Task.isCancelled else { return }
                suggestions = results
                showSuggestions = !results.isEmpty
            } catch {
                guard !Task.isCancelled else { return }
                suggestions = []
                showSuggestions = false
            }

            isSuggestionsLoading = false
        }

        activeSuggestionTask = task
        await task.value
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    private func addRecentSearch(_ query: String) {
        let normalized = query.lowercased()
        for i in recentSearches.indices.reversed() {
            if recentSearches[i].lowercased() == normalized {
                recentSearches.remove(at: i)
            }
        }
        recentSearches.insert(query, at: 0)
        if recentSearches.count > 8 {
            recentSearches = Array(recentSearches.prefix(8))
        }
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }

    private func restorePersistedStateIfNeeded() {
        guard persistLookupState else { return }

        searchText = UserDefaults.standard.string(forKey: lastSearchTextKey) ?? ""

        guard let data = UserDefaults.standard.data(forKey: lastEntryKey),
              let entry = try? JSONDecoder().decode(DictionaryEntry.self, from: data) else {
            return
        }

        currentEntry = entry
    }

    private func persistStateIfNeeded() {
        guard persistLookupState else { return }

        UserDefaults.standard.set(searchText, forKey: lastSearchTextKey)

        guard let currentEntry,
              let data = try? JSONEncoder().encode(currentEntry) else {
            UserDefaults.standard.removeObject(forKey: lastEntryKey)
            return
        }

        UserDefaults.standard.set(data, forKey: lastEntryKey)
    }

    private func friendlySearchError(_ error: Error) -> String {
        if let localized = error as? LocalizedError, let message = localized.errorDescription {
            return message
        }
        return "We could not find that word right now. Please try another one."
    }
}
