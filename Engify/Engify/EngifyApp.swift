//
//  EngifyApp.swift
//  Engify
//
//  Root SwiftUI App entry point.
//  Created by Do Minh Duy on 04-05-2026.
//
//  WHAT IT DOES:
//  - Marks EngifyApp as the @main application delegate.
//  - Creates three app-wide StateObject managers on creation.
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
//  - .accentColor() and .preferredColorScheme() propagate theme settings to the entire view tree.

import SwiftUI

@main
struct EngifyApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var savedWordsManager = SavedWordsManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var gamificationManager = GamificationManager()
    @StateObject private var learningSettingsManager = LearningSettingsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(savedWordsManager)
                .environmentObject(themeManager)
                .environmentObject(gamificationManager)
                .environmentObject(learningSettingsManager)
                .environment(\.themeAccentColor, themeManager.accentColor)
                .accentColor(themeManager.accentColor)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .id("\(themeManager.accent)_\(themeManager.appearance)_\(themeManager.fontSize)")
        }
    }
}
