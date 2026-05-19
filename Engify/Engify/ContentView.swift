//
//  ContentView.swift
//  Engify
//
//  Root view router for the app.
//  Created by Do Minh Duy on 04-05-2026.
//
//  WHAT IT DOES:
//  - Acts as a conditional router: shows the onboarding IntroView on first launch,
//    or the authenticated app shell for returning users.
//  - Reads a persisted AppStorage flag to determine if the intro has been seen.
//
//  WHEN IT SHOWS:
//  - Immediately after EngifyApp launches, every time the app opens.
//  - The flag is set to true once the user finishes or skips onboarding,
//    so subsequent launches skip the intro.
//
//  HOW IT WORKS:
//  - @AppStorage("hasSeenOnboarding") persists a Bool to UserDefaults.
//  - If a legacy intro flag exists, it migrates automatically to the new key.
//  - If false: renders IntroView (onboarding) which calls onContinue() to set the flag true.
//  - If true: renders AuthGateView, which opens the app shell at Home for signed-in users.

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("engify_has_seen_intro") private var legacyHasSeenIntro = false

    var body: some View {
        ZStack {
            if hasSeenOnboarding {
                AuthGateView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            } else {
                IntroView {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        hasSeenOnboarding = true
                    }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: hasSeenOnboarding)
        .onAppear {
            guard !hasSeenOnboarding, legacyHasSeenIntro else { return }
            hasSeenOnboarding = true
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
