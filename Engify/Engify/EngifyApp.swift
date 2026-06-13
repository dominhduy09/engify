//
//  EngifyApp.swift
//  Engify
//
//  Root SwiftUI App entry point.
//  Created by Do Minh Duy on 04-05-2026.
//
//  WHAT IT DOES:
//  - Marks EngifyApp as the @main application delegate.
//  - Creates five app-wide StateObject managers on creation.
//  - Injects those managers as environment objects so every view in the app can access them.
//
//  WHEN IT RUNS:
//  - Exactly once, when the app process first starts, before any UI appears.
//
//  HOW IT WORKS:
//  - WindowGroup is the standard SwiftUI scene container.
//  - AuthenticationManager: manages login/guest session state across the app.
//  - SavedWordsManager: persists bookmarked words to UserDefaults.
//  - ThemeManager: stores accent color, light/dark mode, and font size preferences.
//  - GamificationManager: manages XP, streaks, lingots, and level progress.
//  - LearningSettingsManager: manages all learning preferences with validation and persistence.
//  - .tint() and .preferredColorScheme() propagate theme settings to the entire view tree.

import SwiftUI
import UserNotifications

@MainActor
@main
struct EngifyApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appNotificationDelegate
    @StateObject private var savedWordsManager = SavedWordsManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var gamificationManager = GamificationManager()
    @StateObject private var learningSettingsManager = LearningSettingsManager()
    @StateObject private var surveyManager: OnboardingSurveyManager
    @StateObject private var authManager: AuthenticationManager

    init() {
        let savedWordsManager = SavedWordsManager()
        let gamificationManager = GamificationManager()
        let surveyManager = OnboardingSurveyManager()

        _savedWordsManager = StateObject(wrappedValue: savedWordsManager)
        _gamificationManager = StateObject(wrappedValue: gamificationManager)
        _surveyManager = StateObject(wrappedValue: surveyManager)
        _authManager = StateObject(
            wrappedValue: AuthenticationManager(
                savedWordsManager: savedWordsManager,
                gamificationManager: gamificationManager,
                surveyManager: surveyManager
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(savedWordsManager)
                .environmentObject(themeManager)
                .environmentObject(gamificationManager)
                .environmentObject(learningSettingsManager)
                .environmentObject(surveyManager)
                .environment(\.themeAccentColor, themeManager.accentColor)
                .tint(themeManager.accentColor)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let appStoreURLUserInfoKey = "appStoreURL"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        guard let urlString = response.notification.request.content.userInfo[appStoreURLUserInfoKey] as? String,
              let url = URL(string: urlString) else {
            return
        }

        Task { @MainActor in
            UIApplication.shared.open(url)
        }
    }
}
