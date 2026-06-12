import Foundation

struct ImageLessonService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchLessons(
        query: String,
        providers: [ImageAPIProviderConfig],
        limit: Int = 12
    ) async throws -> [PracticeImageLesson] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return []
        }

        let configuredProviders = providers.filter {
            $0.isEnabled && !$0.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard let provider = configuredProviders.first else {
            throw ImageLessonServiceError.noConfiguredProvider
        }

        switch provider.id {
        case "pexels":
            return try await searchPexels(query: normalizedQuery, provider: provider, limit: limit)
        case "unsplash":
            return try await searchUnsplash(query: normalizedQuery, provider: provider, limit: limit)
        case "pixabay":
            return try await searchPixabay(query: normalizedQuery, provider: provider, limit: limit)
        default:
            throw ImageLessonServiceError.unsupportedProvider(provider.name)
        }
    }

    private func searchPexels(
        query: String,
        provider: ImageAPIProviderConfig,
        limit: Int
    ) async throws -> [PracticeImageLesson] {
        guard var components = URLComponents(string: provider.baseURL) else {
            throw ImageLessonServiceError.invalidProviderURL(provider.name)
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: String(limit))
        ]

        guard let url = components.url else {
            throw ImageLessonServiceError.invalidProviderURL(provider.name)
        }

        var request = URLRequest(url: url)
        request.setValue(provider.apiKey, forHTTPHeaderField: "Authorization")

        let response: PexelsSearchResponse = try await perform(request, providerName: provider.name)
        return response.photos.compactMap { photo in
            guard let imageURL = URL(string: photo.src.large2x ?? photo.src.large ?? photo.src.medium ?? photo.src.original),
                  let attributionURL = URL(string: "https://www.pexels.com") else {
                return nil
            }

            let creatorProfileURL = photo.photographerURL.flatMap(URL.init(string:))
            let sourcePageURL = photo.url.flatMap(URL.init(string:))
            return buildLesson(
                query: query,
                providerName: provider.name,
                providerAttributionURL: attributionURL,
                sourcePageURL: sourcePageURL,
                creatorName: photo.photographer,
                creatorProfileURL: creatorProfileURL,
                imageURL: imageURL,
                descriptor: photo.alt
            )
        }
    }

    private func searchUnsplash(
        query: String,
        provider: ImageAPIProviderConfig,
        limit: Int
    ) async throws -> [PracticeImageLesson] {
        guard var components = URLComponents(string: provider.baseURL) else {
            throw ImageLessonServiceError.invalidProviderURL(provider.name)
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: String(limit)),
            URLQueryItem(name: "client_id", value: provider.apiKey)
        ]

        guard let url = components.url else {
            throw ImageLessonServiceError.invalidProviderURL(provider.name)
        }

        let response: UnsplashSearchResponse = try await perform(URLRequest(url: url), providerName: provider.name)
        return response.results.compactMap { result in
            guard let imageURLString = result.urls.regular ?? result.urls.small ?? result.urls.raw,
                  let imageURL = URL(string: imageURLString),
                  let attributionURL = URL(string: "https://unsplash.com") else {
                return nil
            }

            let creatorProfileURL = result.user.links.html.flatMap(URL.init(string:))
            let sourcePageURL = result.links.html.flatMap(URL.init(string:))
            let descriptor = result.altDescription ?? result.description

            return buildLesson(
                query: query,
                providerName: provider.name,
                providerAttributionURL: attributionURL,
                sourcePageURL: sourcePageURL,
                creatorName: result.user.name,
                creatorProfileURL: creatorProfileURL,
                imageURL: imageURL,
                descriptor: descriptor
            )
        }
    }

    private func searchPixabay(
        query: String,
        provider: ImageAPIProviderConfig,
        limit: Int
    ) async throws -> [PracticeImageLesson] {
        guard var components = URLComponents(string: provider.baseURL) else {
            throw ImageLessonServiceError.invalidProviderURL(provider.name)
        }

        components.queryItems = [
            URLQueryItem(name: "key", value: provider.apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "image_type", value: "photo"),
            URLQueryItem(name: "per_page", value: String(limit))
        ]

        guard let url = components.url else {
            throw ImageLessonServiceError.invalidProviderURL(provider.name)
        }

        let response: PixabaySearchResponse = try await perform(URLRequest(url: url), providerName: provider.name)
        return response.hits.compactMap { hit in
            guard let imageURLString = hit.largeImageURL ?? hit.webformatURL,
                  let imageURL = URL(string: imageURLString),
                  let attributionURL = URL(string: "https://pixabay.com") else {
                return nil
            }

            let sourcePageURL = hit.pageURL.flatMap(URL.init(string:))

            return buildLesson(
                query: query,
                providerName: provider.name,
                providerAttributionURL: attributionURL,
                sourcePageURL: sourcePageURL,
                creatorName: hit.user,
                creatorProfileURL: nil,
                imageURL: imageURL,
                descriptor: hit.tags
            )
        }
    }

    private func perform<T: Decodable>(_ request: URLRequest, providerName: String) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageLessonServiceError.networkFailure(providerName)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw ImageLessonServiceError.invalidAPIKey(providerName)
            }
            throw ImageLessonServiceError.requestFailed(providerName, httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ImageLessonServiceError.decodingFailure(providerName)
        }
    }

    private func buildLesson(
        query: String,
        providerName: String,
        providerAttributionURL: URL?,
        sourcePageURL: URL?,
        creatorName: String?,
        creatorProfileURL: URL?,
        imageURL: URL,
        descriptor: String?
    ) -> PracticeImageLesson {
        let cleanedDescriptor = descriptor?
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let topicTokens = topicKeywords(from: query, descriptor: cleanedDescriptor)
        let focusWords = focusVocabulary(from: query, descriptor: cleanedDescriptor)
        let title = lessonTitle(from: query, descriptor: cleanedDescriptor)
        let summary = sceneDescription(for: query, descriptor: cleanedDescriptor)

        return PracticeImageLesson(
            title: title,
            locationLabel: "\(providerName) Web Result",
            systemImage: systemImage(for: query),
            imageURL: imageURL,
            providerName: providerName,
            providerAttributionURL: providerAttributionURL,
            sourcePageURL: sourcePageURL,
            creatorName: creatorName,
            creatorProfileURL: creatorProfileURL,
            visualStyle: cleanedDescriptor?.isEmpty == false ? cleanedDescriptor! : "Web image result for \(query)",
            searchTopics: topicTokens,
            sceneDescription: summary,
            focusVocabulary: focusWords,
            guidedPrompts: guidedPrompts(for: query, descriptor: cleanedDescriptor),
            challengePrompt: challengePrompt(for: query)
        )
    }

    private func lessonTitle(from query: String, descriptor: String?) -> String {
        if let descriptor, !descriptor.isEmpty {
            let words = descriptor.split(separator: " ").prefix(5).map(String.init)
            if !words.isEmpty {
                return words.joined(separator: " ").capitalized
            }
        }
        return "\(query.capitalized) Scene"
    }

    private func sceneDescription(for query: String, descriptor: String?) -> String {
        if let descriptor, !descriptor.isEmpty {
            return "This web result shows \(descriptor.lowercased()). Describe what stands out, what is happening, and how the scene connects to \(query.lowercased())."
        }
        return "This web result matches \(query.lowercased()). Describe the main objects, actions, and details you notice in the scene."
    }

    private func guidedPrompts(for query: String, descriptor: String?) -> [String] {
        let detailCue = descriptor?.isEmpty == false ? "Use the scene clue '\(descriptor!)' in one sentence." : "Name the first three things you notice."
        return [
            "Start with one simple sentence about the main subject of the picture.",
            detailCue,
            "Add one sentence about color, location, or movement.",
            "Connect the image to your own experience with \(query.lowercased())."
        ]
    }

    private func challengePrompt(for query: String) -> String {
        "Challenge: speak for 30 seconds about this \(query.lowercased()) image without stopping, then add one opinion sentence."
    }

    private func topicKeywords(from query: String, descriptor: String?) -> [String] {
        let raw = [query, descriptor ?? ""]
            .joined(separator: " ")
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { String($0).lowercased() }
            .filter { $0.count > 2 }

        return Array(NSOrderedSet(array: raw).compactMap { $0 as? String }).prefix(8).map { $0 }
    }

    private func focusVocabulary(from query: String, descriptor: String?) -> [String] {
        let baseWords = topicKeywords(from: query, descriptor: descriptor).map { $0.capitalized }
        let fallback = ["Describe", "Notice", "Compare", "Background", "Action"]
        return Array((baseWords + fallback).prefix(6))
    }

    private func systemImage(for query: String) -> String {
        let value = query.lowercased()
        if value.contains("food") || value.contains("coffee") || value.contains("restaurant") {
            return "fork.knife"
        }
        if value.contains("beach") || value.contains("ocean") {
            return "beach.umbrella.fill"
        }
        if value.contains("office") || value.contains("business") || value.contains("team") {
            return "person.3.fill"
        }
        if value.contains("flower") || value.contains("garden") || value.contains("nature") {
            return "camera.macro"
        }
        if value.contains("travel") || value.contains("airport") {
            return "airplane.departure"
        }
        return "photo.fill.on.rectangle.fill"
    }
}

enum ImageLessonServiceError: LocalizedError {
    case noConfiguredProvider
    case invalidProviderURL(String)
    case invalidAPIKey(String)
    case requestFailed(String, Int)
    case unsupportedProvider(String)
    case decodingFailure(String)
    case networkFailure(String)

    var errorDescription: String? {
        switch self {
        case .noConfiguredProvider:
            return "Add an image API key in Settings before searching the web for image lessons."
        case let .invalidProviderURL(provider):
            return "\(provider) has an invalid API URL in Settings."
        case let .invalidAPIKey(provider):
            return "\(provider) rejected the API key. Update it in Settings and try again."
        case let .requestFailed(provider, statusCode):
            return "\(provider) returned an error (\(statusCode)). Try again in a moment."
        case let .unsupportedProvider(provider):
            return "\(provider) is saved, but Engify does not support its response format yet."
        case let .decodingFailure(provider):
            return "Engify could not read the response from \(provider)."
        case let .networkFailure(provider):
            return "Engify could not reach \(provider). Check your connection and try again."
        }
    }
}

private struct PexelsSearchResponse: Decodable {
    let photos: [PexelsPhoto]
}

private struct PexelsPhoto: Decodable {
    let alt: String?
    let photographer: String?
    let photographerURL: String?
    let src: PexelsPhotoSource
    let url: String?

    private enum CodingKeys: String, CodingKey {
        case alt
        case photographer
        case photographerURL = "photographer_url"
        case src
        case url
    }
}

private struct PexelsPhotoSource: Decodable {
    let original: String
    let large2x: String?
    let large: String?
    let medium: String?
}

private struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

private struct UnsplashPhoto: Decodable {
    let description: String?
    let altDescription: String?
    let urls: UnsplashPhotoURLs
    let links: UnsplashPhotoLinks
    let user: UnsplashUser

    private enum CodingKeys: String, CodingKey {
        case description
        case altDescription = "alt_description"
        case urls
        case links
        case user
    }
}

private struct UnsplashPhotoURLs: Decodable {
    let raw: String?
    let regular: String?
    let small: String?
}

private struct UnsplashPhotoLinks: Decodable {
    let html: String?
}

private struct UnsplashUser: Decodable {
    let name: String?
    let links: UnsplashUserLinks
}

private struct UnsplashUserLinks: Decodable {
    let html: String?
}

private struct PixabaySearchResponse: Decodable {
    let hits: [PixabayHit]
}

private struct PixabayHit: Decodable {
    let tags: String?
    let user: String?
    let pageURL: String?
    let largeImageURL: String?
    let webformatURL: String?
    let userImageURL: String?

    private enum CodingKeys: String, CodingKey {
        case tags
        case user
        case pageURL
        case largeImageURL
        case webformatURL
        case userImageURL
    }
}
