import Foundation

/// Network service for fetching news articles.
///
/// WHAT IT DOES:
/// - fetchArticles(): calls newsapi.org if apiKey is configured, otherwise returns
///   EngifySampleData.articles as fallback content.
/// - Extracts difficult words from article text, estimates reading time, and generates
///   comprehension quiz questions for each article.
///
/// WHEN IT SHOWS:
/// - Called by NewsViewModel.loadArticles() when the News tab first appears.
/// - If the API key is still "YOUR_API_KEY_HERE", sample articles are used so the
///   app is fully functional without a live API key.
///
/// HOW IT WORKS:
/// - newsapi.org returns JSON with title, description, content, url, publishedAt, source.
/// - estimateReadingTime() assumes 160 words per minute (industry average).
/// - extractDifficultWords() picks words ≥ 7 characters from the article text.
/// - sampleQuestions() generates two generic comprehension questions per article.
struct NewsService {
    let apiKey: String
    private let session: URLSession

    init(apiKey: String = "YOUR_API_KEY_HERE", session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func fetchArticles(page: Int = 1) async -> [Article] {
        guard apiKey != "YOUR_API_KEY_HERE" else {
            return EngifySampleData.articles
        }

        do {
            let pageSize = 10
            let urlString = "https://newsapi.org/v2/top-headlines?language=en&pageSize=\(pageSize)&page=\(page)&apiKey=\(apiKey)"
            guard let url = URL(string: urlString) else {
                return EngifySampleData.articles
            }

            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                return EngifySampleData.articles
            }

            let apiResponse = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
            var articles: [Article] = []

            for article in apiResponse.articles {
                guard let url = URL(string: article.url) else { continue }

                let summary = article.description ?? "Read the full article to learn more."
                let content = article.content ?? summary
                let readingTime = estimateReadingTime(text: content)

                articles.append(
                    Article(
                        title: article.title,
                        source: article.source.name,
                        category: article.source.name,
                        publishedDate: article.publishedAt.displayDate,
                        readingTime: readingTime,
                        summary: summary,
                        content: content,
                        difficultWords: extractDifficultWords(from: content),
                        questions: sampleQuestions(for: article.title, summary: summary),
                        url: url
                    )
                )
            }

            return articles.isEmpty ? EngifySampleData.articles : articles
        } catch {
            return EngifySampleData.articles
        }
    }

    private func estimateReadingTime(text: String) -> String {
        let wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
        let minutes = max(1, Int(ceil(Double(wordCount) / 160.0)))
        return "\(minutes) min"
    }

    private func extractDifficultWords(from text: String) -> [String] {
        let allWords = text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        var longWords: [String] = []
        for word in allWords where word.count >= 7 {
            longWords.append(word)
        }
        let unique = Array(Set(longWords))
        let sorted = unique.sorted()
        return Array(sorted.prefix(4))
    }

    private func sampleQuestions(for title: String, summary: String) -> [QuizQuestion] {
        [
            QuizQuestion(
                prompt: "What is the article mainly about?",
                options: [title, summary, "A random topic", "Nothing important"],
                answerIndex: 0,
                explanation: "The title is the best clue for the main topic."
            ),
            QuizQuestion(
                prompt: "What should the learner do after reading?",
                options: ["Skip the article", "Answer the quiz", "Close the app", "Start over immediately"],
                answerIndex: 1,
                explanation: "The comprehension quiz helps reinforce reading."
            )
        ]
    }
}

private struct NewsAPIResponse: Decodable {
    let articles: [NewsAPIArticle]
}

private struct NewsAPIArticle: Decodable {
    let title: String
    let description: String?
    let content: String?
    let url: String
    let publishedAt: String
    let source: NewsAPISource
}

private struct NewsAPISource: Decodable {
    let name: String
}

private extension String {
    var displayDate: String {
        guard let date = ISO8601DateFormatter().date(from: self) else {
            return self
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
