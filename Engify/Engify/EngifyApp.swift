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

@main
struct EngifyApp: App {
    @StateObject private var savedWordsManager = SavedWordsManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var gamificationManager = GamificationManager()
    @StateObject private var learningSettingsManager = LearningSettingsManager()
    @StateObject private var authManager: AuthenticationManager

    init() {
        let savedWordsManager = SavedWordsManager()
        let gamificationManager = GamificationManager()

        _savedWordsManager = StateObject(wrappedValue: savedWordsManager)
        _gamificationManager = StateObject(wrappedValue: gamificationManager)
        _authManager = StateObject(
            wrappedValue: AuthenticationManager(
                savedWordsManager: savedWordsManager,
                gamificationManager: gamificationManager
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
                .environment(\.themeAccentColor, themeManager.accentColor)
                .tint(themeManager.accentColor)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}
