import Foundation
import Supabase

struct SupabaseConfiguration {
    let url: URL
    let anonKey: String

    static func load() throws -> SupabaseConfiguration {
        let environment = ProcessInfo.processInfo.environment

        let urlString = environment["SUPABASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let anonKey = environment["SUPABASE_ANON_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        guard let urlString, !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SupabaseConfigurationError.missingURL
        }

        guard let anonKey, !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SupabaseConfigurationError.missingAnonKey
        }

        guard let url = URL(string: urlString) else {
            throw SupabaseConfigurationError.invalidURL(urlString)
        }

        return SupabaseConfiguration(url: url, anonKey: anonKey)
    }
}

enum SupabaseConfigurationError: LocalizedError {
    case missingURL
    case missingAnonKey
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "Missing SUPABASE_URL. Add it to your run scheme environment variables or Info.plist."
        case .missingAnonKey:
            return "Missing SUPABASE_ANON_KEY. Add it to your run scheme environment variables or Info.plist."
        case let .invalidURL(value):
            return "SUPABASE_URL is invalid: \(value)"
        }
    }
}

final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    let configuration: SupabaseConfiguration?
    let client: SupabaseClient?
    let configurationError: SupabaseConfigurationError?

    private init() {
        do {
            let configuration = try SupabaseConfiguration.load()
            self.configuration = configuration
            self.client = SupabaseClient(
                supabaseURL: configuration.url,
                supabaseKey: configuration.anonKey
            )
            self.configurationError = nil
        } catch let error as SupabaseConfigurationError {
            self.configuration = nil
            self.client = nil
            self.configurationError = error
        } catch {
            self.configuration = nil
            self.client = nil
            self.configurationError = .missingURL
        }
    }
}
