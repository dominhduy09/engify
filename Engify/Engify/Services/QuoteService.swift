import Foundation

/// Service that fetches a daily inspirational quote from the ZenQuotes API.
///
/// WHAT IT DOES:
/// - Fetches a random quote from zenquotes.io (free, no API key needed).
/// - Caches the quote locally so it stays the same for the entire day.
/// - Uses a date-based key to automatically rotate quotes daily with no duplicates within a session.
/// - Provides a fallback pool of curated learning-themed quotes if the API is unavailable.
///
/// HOW IT WORKS:
/// - On first call each day, it fetches from the API and caches the result in UserDefaults.
/// - Subsequent calls on the same day return the cached quote instantly.
/// - Tracks previously shown quotes (up to 60) to avoid short-term duplicates.
/// - Falls back to a curated local pool if the network request fails.
struct QuoteService {
    private let session: URLSession
    private static let cacheKey = "engify.dailyQuote"
    private static let cacheDateKey = "engify.dailyQuote.date"
    private static let shownQuotesKey = "engify.dailyQuote.shown"

    init(session: URLSession = .shared) {
        self.session = session
    }

    struct DailyQuote: Codable, Equatable {
        let text: String
        let author: String
    }

    /// Returns today's quote — cached if already fetched today, otherwise fetches fresh.
    func fetchDailyQuote() async -> DailyQuote {
        // Check if we already have a quote for today
        let today = Self.todayString()
        if let cached = Self.cachedQuote(), Self.cachedDate() == today {
            return cached
        }

        // Fetch from API
        do {
            let quote = try await fetchFromAPI()
            Self.cacheQuote(quote, date: today)
            Self.trackShownQuote(quote.text)
            return quote
        } catch {
            // Fallback to local quotes
            return Self.fallbackQuote()
        }
    }

    private func fetchFromAPI() async throws -> DailyQuote {
        guard let url = URL(string: "https://zenquotes.io/api/random") else {
            throw QuoteServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw QuoteServiceError.networkError
        }

        let results = try JSONDecoder().decode([ZenQuoteResponse].self, from: data)
        guard let first = results.first else {
            throw QuoteServiceError.noQuote
        }

        return DailyQuote(text: first.q, author: first.a)
    }

    // MARK: - Cache

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func cachedQuote() -> DailyQuote? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(DailyQuote.self, from: data)
    }

    private static func cachedDate() -> String? {
        UserDefaults.standard.string(forKey: cacheDateKey)
    }

    private static func cacheQuote(_ quote: DailyQuote, date: String) {
        if let data = try? JSONEncoder().encode(quote) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(date, forKey: cacheDateKey)
        }
    }

    private static func trackShownQuote(_ text: String) {
        var shown = UserDefaults.standard.stringArray(forKey: shownQuotesKey) ?? []
        if !shown.contains(text) {
            shown.append(text)
            if shown.count > 60 { shown.removeFirst() }
            UserDefaults.standard.set(shown, forKey: shownQuotesKey)
        }
    }

    private static func shownQuotes() -> [String] {
        UserDefaults.standard.stringArray(forKey: shownQuotesKey) ?? []
    }

    // MARK: - Fallback

    static func fallbackQuote() -> DailyQuote {
        let shown = shownQuotes()
        let available = fallbackQuotes.filter { !shown.contains($0.text) }
        let quote = available.randomElement() ?? fallbackQuotes.randomElement()!
        trackShownQuote(quote.text)
        return quote
    }

    private static let fallbackQuotes: [DailyQuote] = [
        DailyQuote(text: "The limits of my language mean the limits of my world.", author: "Ludwig Wittgenstein"),
        DailyQuote(text: "One language sets you in a corridor for life. Two languages open every door along the way.", author: "Frank Smith"),
        DailyQuote(text: "To have another language is to possess a second soul.", author: "Charlemagne"),
        DailyQuote(text: "Language is the road map of a culture.", author: "Rita Mae Brown"),
        DailyQuote(text: "Learning another language is not only learning different words for the same things, but learning another way to think about things.", author: "Flora Lewis"),
        DailyQuote(text: "A different language is a different vision of life.", author: "Federico Fellini"),
        DailyQuote(text: "The more that you read, the more things you will know. The more that you learn, the more places you'll go.", author: "Dr. Seuss"),
        DailyQuote(text: "You can never understand one language until you understand at least two.", author: "Geoffrey Willans"),
        DailyQuote(text: "Language is the dress of thought.", author: "Samuel Johnson"),
        DailyQuote(text: "With languages, you are at home anywhere.", author: "Edmund de Waal"),
        DailyQuote(text: "Knowledge of languages is the doorway to wisdom.", author: "Roger Bacon"),
        DailyQuote(text: "If you talk to a man in a language he understands, that goes to his head. If you talk to him in his own language, that goes to his heart.", author: "Nelson Mandela"),
        DailyQuote(text: "The beautiful thing about learning is that nobody can take it away from you.", author: "B.B. King"),
        DailyQuote(text: "Education is not the filling of a pail, but the lighting of a fire.", author: "W.B. Yeats"),
        DailyQuote(text: "Live as if you were to die tomorrow. Learn as if you were to live forever.", author: "Mahatma Gandhi"),
        DailyQuote(text: "The expert in anything was once a beginner.", author: "Helen Hayes"),
        DailyQuote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
        DailyQuote(text: "Every accomplishment starts with the decision to try.", author: "John F. Kennedy"),
        DailyQuote(text: "Success is the sum of small efforts, repeated day in and day out.", author: "Robert Collier"),
        DailyQuote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
        DailyQuote(text: "Tell me and I forget. Teach me and I remember. Involve me and I learn.", author: "Benjamin Franklin"),
        DailyQuote(text: "Learning never exhausts the mind.", author: "Leonardo da Vinci"),
        DailyQuote(text: "The roots of education are bitter, but the fruit is sweet.", author: "Aristotle"),
        DailyQuote(text: "An investment in knowledge pays the best interest.", author: "Benjamin Franklin"),
        DailyQuote(text: "The beginning is the most important part of the work.", author: "Plato"),
        DailyQuote(text: "Practice is the hardest part of learning, and training is the essence of transformation.", author: "Ann Voskamp"),
        DailyQuote(text: "Small disciplines repeated with consistency every day lead to great achievements gained slowly over time.", author: "John C. Maxwell"),
        DailyQuote(text: "We learn by example and by direct experience because there are real limits to the adequacy of verbal instruction.", author: "Malcolm Gladwell"),
        DailyQuote(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
        DailyQuote(text: "Courage doesn't always roar. Sometimes courage is the quiet voice at the end of the day saying, I will try again tomorrow.", author: "Mary Anne Radmacher"),
        DailyQuote(text: "What we learn with pleasure we never forget.", author: "Alfred Mercier"),
        DailyQuote(text: "Do not wait to strike till the iron is hot; but make it hot by striking.", author: "William Butler Yeats"),
        DailyQuote(text: "Well done is better than well said.", author: "Benjamin Franklin"),
        DailyQuote(text: "You don't have to be great to start, but you have to start to be great.", author: "Zig Ziglar"),
        DailyQuote(text: "Discipline is choosing between what you want now and what you want most.", author: "Abraham Lincoln"),
        DailyQuote(text: "Success is the product of daily habits, not once-in-a-lifetime transformations.", author: "James Clear"),
        DailyQuote(text: "The more you practice, the easier it gets. Not because the task becomes easy, but because your skill becomes greater.", author: "Unknown"),
        DailyQuote(text: "A little progress each day adds up to big results.", author: "Satya Nani"),
        DailyQuote(text: "The man who moves a mountain begins by carrying away small stones.", author: "Confucius"),
        DailyQuote(text: "Patience, persistence and perspiration make an unbeatable combination for success.", author: "Napoleon Hill"),
    ]
}

private enum QuoteServiceError: Error {
    case invalidURL
    case networkError
    case noQuote
}

private struct ZenQuoteResponse: Decodable {
    let q: String  // quote text
    let a: String  // author
}
