//
//  ContentView.swift
//  Engify
//
//  Root view router for the app.
//  Created by Do Minh Duy on 04-05-2026.
//
//  WHAT IT DOES:
//  - Acts as a conditional router: shows the onboarding IntroView on first launch,
//    or MainTabView (the main app shell) for returning users.
//  - Reads a persisted AppStorage flag to determine if the intro has been seen.
//
//  WHEN IT SHOWS:
//  - Immediately after EngifyApp launches, every time the app opens.
//  - The flag is set to true once the user taps "Start Learning" in IntroView,
//    so subsequent launches skip the intro.
//
//  HOW IT WORKS:
//  - @AppStorage("engify_has_seen_intro") persists a Bool to UserDefaults.
//  - If false: renders IntroView (onboarding) which calls onContinue() to set the flag true.
//  - If true: renders MainTabView (the tabbed main screen).

import SwiftUI

struct ContentView: View {
    @AppStorage("engify_has_seen_intro") private var hasSeenIntro = false

    var body: some View {
        Group {
            if hasSeenIntro {
                AuthGateView()
            } else {
                IntroView {
                    hasSeenIntro = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SavedWordsManager())
        .environmentObject(ThemeManager())
        .environmentObject(GamificationManager())
}
