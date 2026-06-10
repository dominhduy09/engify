import Foundation
import Combine

@MainActor
final class OnboardingSurveyManager: ObservableObject {
    private enum Keys {
        static let hasCompletedSurvey = "engify.onboarding.survey.completed"
        static let cachedResponse = "engify.onboarding.survey.cached-response"
    }

    @Published private(set) var hasCompletedSurvey: Bool
    @Published private(set) var cachedResponse: OnboardingSurveyResponse?

    private let supabaseManager: SupabaseManager

    init(supabaseManager: SupabaseManager? = nil) {
        self.supabaseManager = supabaseManager ?? .shared
        self.hasCompletedSurvey = UserDefaults.standard.bool(forKey: Keys.hasCompletedSurvey)

        if let data = UserDefaults.standard.data(forKey: Keys.cachedResponse),
           let decoded = try? JSONDecoder().decode(OnboardingSurveyResponse.self, from: data) {
            self.cachedResponse = decoded
        } else {
            self.cachedResponse = nil
        }
    }

    func saveLocally(_ response: OnboardingSurveyResponse) {
        cachedResponse = response
        hasCompletedSurvey = true

        if let encoded = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(encoded, forKey: Keys.cachedResponse)
        }
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedSurvey)
    }

    func submit(_ response: OnboardingSurveyResponse) async {
        saveLocally(response)
        await syncIfPossible()
    }

    func syncIfPossible() async {
        guard let cachedResponse, supabaseManager.currentUser != nil else { return }

        do {
            try await supabaseManager.saveOnboardingSurvey(cachedResponse)
        } catch {
            print("Failed to sync onboarding survey: \(error.localizedDescription)")
        }
    }
}
