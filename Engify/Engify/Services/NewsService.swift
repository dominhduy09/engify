import Foundation

/// RSS-driven news lesson service.
///
/// WHAT IT DOES:
/// - Fetches free public RSS feeds and maps them into Article lessons.
/// - Optionally sends article text to a free Hugging Face inference endpoint when a token is configured.
/// - Falls back to bundled local lessons if feeds or AI processing are unavailable.
///
/// HOW IT WORKS:
/// - RSS items are parsed with XMLParser into a simple feed item model.
/// - Each item is transformed into an Article with summary, reading time, category, vocabulary, and quiz data.
/// - When HUGGING_FACE_TOKEN is available, the service asks the model for structured JSON and validates it.
struct NewsService {
    private let session: URLSession
    private let huggingFaceToken: String?
    private let fallbackLoader: NewsFallbackLoader

    init(
        session: URLSession = .shared,
        huggingFaceToken: String? = NewsService.loadHuggingFaceToken()
    ) {
        self.session = session
        self.huggingFaceToken = huggingFaceToken?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.fallbackLoader = NewsFallbackLoader()
    }

    func fetchArticles(page: Int = 1) async -> [Article] {
        let feedItems = await fetchRSSItems()
        let pagedItems = paginate(feedItems, page: page, pageSize: 10)

        guard !pagedItems.isEmpty else {
            return fallbackArticles(page: page)
        }

        var processedArticles: [Article] = []
        for item in pagedItems {
            if let article = await buildArticle(from: item) {
                processedArticles.append(article)
            }
        }

        if processedArticles.isEmpty {
            return fallbackArticles(page: page)
        }

        return processedArticles
    }

    private func fetchRSSItems() async -> [RSSFeedItem] {
        let feeds = NewsFeedSource.allCases

        return await withTaskGroup(of: [RSSFeedItem].self) { group in
            for feed in feeds {
                group.addTask {
                    await fetchItems(from: feed)
                }
            }

            var allItems: [RSSFeedItem] = []
            for await items in group {
                allItems.append(contentsOf: items)
            }

            let sortedItems = allItems.sorted { lhs, rhs in
                lhs.date ?? .distantPast > rhs.date ?? .distantPast
            }

            var seenKeys = Set<String>()
            var uniqueItems: [RSSFeedItem] = []

            for item in sortedItems {
                let key = item.link?.absoluteString.lowercased()
                    ?? "\(item.source.publisherName)|\(item.title)".lowercased()

                if seenKeys.insert(key).inserted {
                    uniqueItems.append(item)
                }
            }

            return uniqueItems
        }
    }

    private func fetchItems(from feed: NewsFeedSource) async -> [RSSFeedItem] {
        guard let url = URL(string: feed.urlString) else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                return []
            }

            let parser = RSSFeedParser(source: feed)
            return parser.parse(data: data)
        } catch {
            return []
        }
    }

    private func buildArticle(from item: RSSFeedItem) async -> Article? {
        let rawText = sanitizedArticleText(from: item)
        guard !rawText.isEmpty else { return nil }

        let transformed = await transformArticleText(
            text: rawText,
            fallbackTitle: item.title,
            category: item.source.defaultCategory
        )

        let title = transformed?.title.nonEmpty ?? cleanedHeadline(item.title)
        let category = transformed?.category.nonEmpty ?? item.source.defaultCategory
        let summary = transformed?.shortSummary.nonEmpty ?? summaryFromText(rawText)
        let keyVocabulary = normalizedVocabulary(from: transformed?.keyVocabulary ?? [], text: rawText)
        let content = rawText
        let readingTime = transformed?.readingTime.nonEmpty ?? estimateReadingTime(text: content)
        let difficultWords = keyVocabulary.map(\.word).prefix(4).map { $0 }
        let quiz = sampleQuestions(for: title, summary: summary, category: category)

        return Article(
            title: title,
            source: item.source.publisherName,
            category: category,
            publishedDate: formatDisplayDate(item.dateString),
            readingTime: readingTime,
            summary: summary,
            content: content,
            difficultWords: difficultWords.isEmpty ? extractDifficultWords(from: content) : difficultWords,
            keyVocabulary: keyVocabulary,
            questions: quiz,
            url: item.link
        )
    }

    private func transformArticleText(
        text: String,
        fallbackTitle: String,
        category: String
    ) async -> HuggingFaceLessonResponse? {
        guard let token = huggingFaceToken, !token.isEmpty else {
            return localLessonTransform(text: text, fallbackTitle: fallbackTitle, category: category)
        }

        guard let url = URL(string: "https://api-inference.huggingface.co/models/Qwen/Qwen2.5-7B-Instruct") else {
            return localLessonTransform(text: text, fallbackTitle: fallbackTitle, category: category)
        }

        let prompt = """
        You are an open-source educational JSON generation model. Analyze the input news text string. Output a raw, valid JSON block. Do not wrap code block markdown syntax or print introduction text.

        Input Text:
        \(text)

        Target Schema output:
        {
          "title": "Cleaned simplified headline",
          "category": "Single-word string (e.g., Tech, Space, General)",
          "readingTime": "e.g., '2 min'",
          "shortSummary": "A highly readable 2-sentence explanation of this news item.",
          "keyVocabulary": [
            {
              "word": "Advanced word found inside text",
              "partOfSpeech": "Noun/Verb/Adjective",
              "phonetic": "/accurate_ipa_string/",
              "vietnameseMeaning": "Contextual Vietnamese translation definition string",
              "example": "A clean simple sentence using the word."
            }
          ]
        }
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = HuggingFaceRequest(inputs: prompt, parameters: .init(maxNewTokens: 500, returnFullText: false))
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                return localLessonTransform(text: text, fallbackTitle: fallbackTitle, category: category)
            }

            if let lesson = decodeLessonResponse(from: data) {
                return lesson
            }
        } catch {
            return localLessonTransform(text: text, fallbackTitle: fallbackTitle, category: category)
        }

        return localLessonTransform(text: text, fallbackTitle: fallbackTitle, category: category)
    }

    private func decodeLessonResponse(from data: Data) -> HuggingFaceLessonResponse? {
        if let arrayResponse = try? JSONDecoder().decode([HuggingFaceGeneratedText].self, from: data),
           let generated = arrayResponse.first?.generatedText {
            return extractLessonJSON(from: generated)
        }

        if let direct = try? JSONDecoder().decode(HuggingFaceLessonResponse.self, from: data) {
            return direct
        }

        return nil
    }

    private func extractLessonJSON(from rawText: String) -> HuggingFaceLessonResponse? {
        guard let start = rawText.firstIndex(of: "{"), let end = rawText.lastIndex(of: "}") else {
            return nil
        }

        let jsonText = String(rawText[start...end])
        guard let data = jsonText.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(HuggingFaceLessonResponse.self, from: data)
    }

    private func localLessonTransform(
        text: String,
        fallbackTitle: String,
        category: String
    ) -> HuggingFaceLessonResponse {
        let title = cleanedHeadline(fallbackTitle)
        let summary = summaryFromText(text)
        let vocabulary = heuristicVocabulary(from: text)

        return HuggingFaceLessonResponse(
            title: title,
            category: category,
            readingTime: estimateReadingTime(text: text),
            shortSummary: summary,
            keyVocabulary: vocabulary
        )
    }

    private func normalizedVocabulary(from items: [LessonVocabularyPayload], text: String) -> [NewsVocabularyItem] {
        let filtered = items.compactMap { item -> NewsVocabularyItem? in
            let word = item.word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard word.count >= 3 else { return nil }

            return NewsVocabularyItem(
                word: word,
                partOfSpeech: item.partOfSpeech.nonEmpty ?? inferPartOfSpeech(for: word),
                phonetic: item.phonetic.nonEmpty ?? approximatePhonetic(for: word),
                vietnameseMeaning: item.vietnameseMeaning.nonEmpty ?? "Từ vựng liên quan đến bài báo",
                example: item.example.nonEmpty ?? simpleExample(for: word)
            )
        }

        if !filtered.isEmpty {
            return Array(filtered.uniqued(on: \.id).prefix(5))
        }

        return heuristicVocabulary(from: text).map {
            NewsVocabularyItem(
                word: $0.word,
                partOfSpeech: $0.partOfSpeech,
                phonetic: $0.phonetic,
                vietnameseMeaning: $0.vietnameseMeaning,
                example: $0.example
            )
        }
    }

    private func heuristicVocabulary(from text: String) -> [LessonVocabularyPayload] {
        let words = text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 7 }

        let uniqueWords = Array(Set(words.map { $0.lowercased() })).sorted().prefix(5)

        return uniqueWords.map { word in
            LessonVocabularyPayload(
                word: word.capitalizingFirstLetterIfNeeded(),
                partOfSpeech: inferPartOfSpeech(for: word),
                phonetic: approximatePhonetic(for: word),
                vietnameseMeaning: "Từ nâng cao xuất hiện trong bài đọc",
                example: simpleExample(for: word)
            )
        }
    }

    private func sampleQuestions(for title: String, summary: String, category: String) -> [QuizQuestion] {
        [
            QuizQuestion(
                prompt: "What is the main topic of this article?",
                options: [title, "A cooking lesson", "A sports schedule", "A random story"],
                answerIndex: 0,
                explanation: "The title names the article's main topic."
            ),
            QuizQuestion(
                prompt: "Which category best matches the article?",
                options: [category, "Shopping", "Weather only", "No category"],
                answerIndex: 0,
                explanation: "The article card labels the lesson with its category."
            ),
            QuizQuestion(
                prompt: "What should you do after reading the summary?",
                options: ["Ignore the article", "Read the full text carefully", "Close the app", "Skip all vocabulary"],
                answerIndex: 1,
                explanation: "Reading the full text helps you notice the key vocabulary in context."
            )
        ]
    }

    private func fallbackArticles(page: Int) -> [Article] {
        let fallback = fallbackLoader.loadFallbackArticles()
        let selected = paginate(fallback, page: page, pageSize: 5)
        return selected.isEmpty ? EngifySampleData.articles : selected
    }

    private func paginate<T>(_ items: [T], page: Int, pageSize: Int) -> [T] {
        guard page > 0 else { return [] }
        let startIndex = (page - 1) * pageSize
        guard startIndex < items.count else { return [] }
        let endIndex = min(startIndex + pageSize, items.count)
        return Array(items[startIndex..<endIndex])
    }

    private func sanitizedArticleText(from item: RSSFeedItem) -> String {
        let combined = [item.description, item.content, item.title]
            .compactMap { $0 }
            .joined(separator: " ")

        return combined
            .strippingHTML()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .condensingWhitespace()
    }

    private func cleanedHeadline(_ text: String) -> String {
        text
            .strippingHTML()
            .condensingWhitespace()
    }

    private func summaryFromText(_ text: String) -> String {
        let sentences = text
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if sentences.count >= 2 {
            return "\(sentences[0]). \(sentences[1])."
        }

        if let first = sentences.first {
            return "\(first)."
        }

        return "This article introduces a recent news story in simple English."
    }

    private func estimateReadingTime(text: String) -> String {
        let wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
        let minutes = max(1, Int(ceil(Double(wordCount) / 160.0)))
        return "\(minutes) min"
    }

    private func extractDifficultWords(from text: String) -> [String] {
        let allWords = text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        let unique = Array(Set(allWords.filter { $0.count >= 7 })).sorted()
        return Array(unique.prefix(4))
    }

    private func inferPartOfSpeech(for word: String) -> String {
        let lowercased = word.lowercased()
        if lowercased.hasSuffix("ing") || lowercased.hasSuffix("ed") {
            return "Verb"
        }
        if lowercased.hasSuffix("ly") || lowercased.hasSuffix("ive") || lowercased.hasSuffix("ous") || lowercased.hasSuffix("al") {
            return "Adjective"
        }
        return "Noun"
    }

    private func approximatePhonetic(for word: String) -> String {
        "/\(word.lowercased())/"
    }

    private func simpleExample(for word: String) -> String {
        "The article helps learners understand the word \(word.lowercased()) in context."
    }

    private func formatDisplayDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return DateFormatter.newsDisplay.string(from: Date()) }

        for formatter in DateFormatter.newsFeedParsers {
            if let date = formatter.date(from: value) {
                return DateFormatter.newsDisplay.string(from: date)
            }
        }

        return value
    }

    private static func loadHuggingFaceToken() -> String? {
        let environment = ProcessInfo.processInfo.environment
        return environment["HUGGING_FACE_TOKEN"]
            ?? environment["HF_TOKEN"]
            ?? Bundle.main.object(forInfoDictionaryKey: "HUGGING_FACE_TOKEN") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "HF_TOKEN") as? String
    }
}

enum NewsFeedSource: CaseIterable {
    case bbcLearningEnglish
    case bbcWorld
    case nasaBreakingNews
    case guardianTopStories
    case guardianWorld
    case guardianScience
    case guardianTechnology
    case guardianSport
    case alJazeeraWorld
    case reutersWorld

    var urlString: String {
        switch self {
        case .bbcLearningEnglish:
            return "https://feeds.bbci.co.uk/learningenglish/english/features/6-minute-english/rss"
        case .bbcWorld:
            return "https://feeds.bbci.co.uk/news/world/rss.xml"
        case .nasaBreakingNews:
            return "https://www.nasa.gov/rss/dyn/breaking_news.rss"
        case .guardianTopStories:
            return "https://www.theguardian.com/rss"
        case .guardianWorld:
            return "https://www.theguardian.com/world/rss"
        case .guardianScience:
            return "https://www.theguardian.com/science/rss"
        case .guardianTechnology:
            return "https://www.theguardian.com/technology/rss"
        case .guardianSport:
            return "https://www.theguardian.com/sport/rss"
        case .alJazeeraWorld:
            return "https://www.aljazeera.com/xml/rss/all.xml"
        case .reutersWorld:
            return "https://feeds.reuters.com/Reuters/worldNews"
        }
    }

    var publisherName: String {
        switch self {
        case .bbcLearningEnglish:
            return "BBC Learning English"
        case .bbcWorld:
            return "BBC News"
        case .nasaBreakingNews:
            return "NASA"
        case .guardianTopStories, .guardianWorld, .guardianScience, .guardianTechnology, .guardianSport:
            return "The Guardian"
        case .alJazeeraWorld:
            return "Al Jazeera"
        case .reutersWorld:
            return "Reuters"
        }
    }

    var defaultCategory: String {
        switch self {
        case .bbcLearningEnglish:
            return "Learning"
        case .bbcWorld, .guardianTopStories, .guardianWorld, .reutersWorld, .alJazeeraWorld:
            return "World"
        case .nasaBreakingNews:
            return "Space"
        case .guardianScience:
            return "Science"
        case .guardianTechnology:
            return "Technology"
        case .guardianSport:
            return "Sports"
        }
    }
}

private struct RSSFeedItem {
    let title: String
    let description: String?
    let content: String?
    let dateString: String?
    let link: URL?
    let source: NewsFeedSource

    var date: Date? {
        guard let dateString else { return nil }
        for formatter in DateFormatter.newsFeedParsers {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}

private final class RSSFeedParser: NSObject, XMLParserDelegate {
    private let source: NewsFeedSource
    private var items: [RSSFeedItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentContent = ""
    private var currentDate = ""
    private var currentLink = ""
    private var isInsideItem = false

    init(source: NewsFeedSource) {
        self.source = source
    }

    func parse(data: Data) -> [RSSFeedItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = qName ?? elementName
        if currentElement == "item" || currentElement == "entry" {
            isInsideItem = true
            currentTitle = ""
            currentDescription = ""
            currentContent = ""
            currentDate = ""
            currentLink = ""
        }

        if isInsideItem, currentElement == "link", let href = attributeDict["href"], currentLink.isEmpty {
            currentLink = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }

        switch currentElement {
        case "title":
            currentTitle += string
        case "description", "summary":
            currentDescription += string
        case "content:encoded", "content":
            currentContent += string
        case "pubDate", "published", "updated":
            currentDate += string
        case "link":
            currentLink += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let element = qName ?? elementName
        if element == "item" || element == "entry" {
            let trimmedTitle = currentTitle.condensingWhitespace()
            guard !trimmedTitle.isEmpty else {
                isInsideItem = false
                return
            }

            items.append(
                RSSFeedItem(
                    title: trimmedTitle,
                    description: currentDescription.condensingWhitespace().nilIfEmpty,
                    content: currentContent.condensingWhitespace().nilIfEmpty,
                    dateString: currentDate.condensingWhitespace().nilIfEmpty,
                    link: URL(string: currentLink.condensingWhitespace()),
                    source: source
                )
            )
            isInsideItem = false
        }
    }
}

private struct HuggingFaceRequest: Encodable {
    let inputs: String
    let parameters: Parameters

    struct Parameters: Encodable {
        let maxNewTokens: Int
        let returnFullText: Bool

        enum CodingKeys: String, CodingKey {
            case maxNewTokens = "max_new_tokens"
            case returnFullText = "return_full_text"
        }
    }
}

private struct HuggingFaceGeneratedText: Decodable {
    let generatedText: String

    enum CodingKeys: String, CodingKey {
        case generatedText = "generated_text"
    }
}

private struct HuggingFaceLessonResponse: Decodable {
    let title: String
    let category: String
    let readingTime: String
    let shortSummary: String
    let keyVocabulary: [LessonVocabularyPayload]
}

private struct LessonVocabularyPayload: Codable, Hashable {
    let word: String
    let partOfSpeech: String
    let phonetic: String
    let vietnameseMeaning: String
    let example: String
}

private struct FallbackNewsArticleDTO: Decodable {
    let title: String
    let source: String
    let category: String
    let publishedDate: String
    let readingTime: String
    let summary: String
    let content: String
    let url: String?
    let keyVocabulary: [NewsVocabularyItem]
    let questions: [QuizQuestion]

    var asArticle: Article {
        Article(
            title: title,
            source: source,
            category: category,
            publishedDate: publishedDate,
            readingTime: readingTime,
            summary: summary,
            content: content,
            difficultWords: keyVocabulary.map(\.word),
            keyVocabulary: keyVocabulary,
            questions: questions,
            url: url.flatMap(URL.init(string:))
        )
    }
}

private struct NewsFallbackLoader {
    func loadFallbackArticles() -> [Article] {
        guard let url = Bundle.main.url(forResource: "free_news_fallback", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([FallbackNewsArticleDTO].self, from: data) else {
            return EngifySampleData.articles
        }

        return decoded.map(\.asArticle)
    }
}

private extension Array {
    func uniqued<T: Hashable>(on keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var nilIfEmpty: String? {
        nonEmpty
    }

    func strippingHTML() -> String {
        replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    func condensingWhitespace() -> String {
        replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func capitalizingFirstLetterIfNeeded() -> String {
        guard let first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}

private extension DateFormatter {
    static let newsDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let newsFeedParsers: [DateFormatter] = {
        let patterns = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        ]

        return patterns.map { pattern in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = pattern
            return formatter
        }
    }()
}
