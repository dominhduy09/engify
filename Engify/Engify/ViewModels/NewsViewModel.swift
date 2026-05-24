import Combine
import Foundation

/// ViewModel for NewsReadingView. Manages article loading state and pagination for unlimited renewal.
///
/// WHAT IT DOES:
/// - Holds the articles array, loading/pagination state, and error handling.
/// - loadArticles() fetches the first page of articles on appear.
/// - loadMoreArticles() fetches the next page for unlimited article renewal.
///
/// WHEN IT SHOWS:
/// - Active while the News tab is open.
/// - Drives the article list, loading skeleton, and refresh functionality in NewsReadingView.
///
/// HOW IT WORKS:
/// - Delegates fetching to NewsService.fetchArticles(page:).
/// - Tracks currentPage to support pagination across multiple API calls.
/// - Can append new articles to existing list or refresh for different content.
@MainActor
final class NewsViewModel: ObservableObject {
    struct NewsFilterState: Equatable {
        var selectedSources: Set<NewsSourceFilter> = []
        var selectedCategories: Set<NewsCategoryFilter> = []
        var searchText: String = ""

        var isActive: Bool {
            !selectedSources.isEmpty || !selectedCategories.isEmpty || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum NewsSourceFilter: String, CaseIterable, Identifiable {
        case bbc = "BBC"
        case nasa = "NASA"
        case guardian = "The Guardian"
        case alJazeera = "Al Jazeera"
        case reuters = "Reuters"
        case bbcLearningEnglish = "BBC Learning English"

        var id: String { rawValue }
    }

    enum NewsCategoryFilter: String, CaseIterable, Identifiable {
        case learning = "Learning"
        case world = "World"
        case space = "Space"
        case science = "Science"
        case technology = "Technology"
        case sports = "Sports"

        var id: String { rawValue }
    }

    @Published var articles: [Article] = []
    @Published var filteredArticles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var isShowingFallbackContent = false
    @Published var filters = NewsFilterState() {
        didSet { applyFilters() }
    }

    private let service: NewsService

    init(service: NewsService? = nil) {
        self.service = service ?? NewsService()
    }

    func loadArticles() async {
        isLoading = true
        errorMessage = nil
        articles = []
        currentPage = 1

        let fetchedArticles = await service.fetchArticles(page: currentPage)
        articles = fetchedArticles
        applyFilters()
        isShowingFallbackContent = fetchedArticles.allSatisfy { $0.source == "Engify News" || $0.source == "Engify Local" }
        isLoading = false

        if fetchedArticles.isEmpty {
            errorMessage = "No articles were found."
        }
    }
    
    func loadMoreArticles() async {
        isLoading = true
        errorMessage = nil
        currentPage += 1
        
        let fetchedArticles = await service.fetchArticles(page: currentPage)
        articles.append(contentsOf: fetchedArticles)
        applyFilters()
        isShowingFallbackContent = articles.allSatisfy { $0.source == "Engify News" || $0.source == "Engify Local" }
        isLoading = false
        
        if fetchedArticles.isEmpty {
            errorMessage = "No more articles available."
            currentPage -= 1
        }
    }
    
    func refreshArticles() async {
        currentPage = 1
        await loadArticles()
    }

    func clearFilters() {
        filters = NewsFilterState()
    }

    func updateSearchText(_ text: String) {
        var updated = filters
        updated.searchText = text
        filters = updated
    }

    func toggleSourceFilter(_ filter: NewsSourceFilter) {
        var updated = filters
        if updated.selectedSources.contains(filter) {
            updated.selectedSources.remove(filter)
        } else {
            updated.selectedSources.insert(filter)
        }
        filters = updated
    }

    func toggleCategoryFilter(_ filter: NewsCategoryFilter) {
        var updated = filters
        if updated.selectedCategories.contains(filter) {
            updated.selectedCategories.remove(filter)
        } else {
            updated.selectedCategories.insert(filter)
        }
        filters = updated
    }

    private func applyFilters() {
        let query = filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        filteredArticles = articles.filter { article in
            let sourceMatches = filters.selectedSources.isEmpty || filters.selectedSources.contains(sourceFilter(for: article.source))
            let categoryMatches = filters.selectedCategories.isEmpty || filters.selectedCategories.contains(categoryFilter(for: article.category))
            let textMatches = query.isEmpty || [article.title, article.summary, article.content, article.source, article.category]
                .joined(separator: " ")
                .lowercased()
                .contains(query)

            return sourceMatches && categoryMatches && textMatches
        }
    }

    private func sourceFilter(for source: String) -> NewsSourceFilter {
        let lowered = source.lowercased()
        if lowered.contains("bbc learning english") { return .bbcLearningEnglish }
        if lowered.contains("bbc") { return .bbc }
        if lowered.contains("nasa") { return .nasa }
        if lowered.contains("guardian") { return .guardian }
        if lowered.contains("al jazeera") { return .alJazeera }
        return .reuters
    }

    private func categoryFilter(for category: String) -> NewsCategoryFilter {
        switch category.lowercased() {
        case "learning": return .learning
        case "space": return .space
        case "science": return .science
        case "technology": return .technology
        case "sports": return .sports
        default: return .world
        }
    }
}
