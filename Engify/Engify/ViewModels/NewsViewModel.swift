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
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var isShowingFallbackContent = false

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
}
