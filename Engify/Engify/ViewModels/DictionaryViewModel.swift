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
    private var cancellables = Set<AnyCancellable>()
    private var suppressNextSuggestionFetch = false

    init(service: DictionaryService? = nil) {
        self.service = service ?? DictionaryService()
        loadRecentSearches()
        bindSearchText()
    }

    func search() async {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            currentEntry = nil
            errorMessage = "Please enter a word to search."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            currentEntry = try await service.searchWord(trimmedText)
            addRecentSearch(trimmedText)
        } catch {
            currentEntry = nil
            errorMessage = friendlySearchError(error)
        }

        isLoading = false
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
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
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

    private func fetchSuggestions(for query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            suggestions = []
            showSuggestions = false
            isSuggestionsLoading = false
            return
        }

        isSuggestionsLoading = true

        do {
            suggestions = try await service.suggestWords(for: trimmed)
            showSuggestions = !suggestions.isEmpty
        } catch {
            suggestions = []
            showSuggestions = false
        }

        isSuggestionsLoading = false
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

    private func friendlySearchError(_ error: Error) -> String {
        if let localized = error as? LocalizedError, let message = localized.errorDescription {
            return message
        }
        return "We could not find that word right now. Please try another one."
    }
}
