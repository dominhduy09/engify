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
    @AppStorage("engify_has_completed_permission_gate") private var hasCompletedPermissionGate = false
    @EnvironmentObject private var surveyManager: OnboardingSurveyManager
    @EnvironmentObject private var learningSettingsManager: LearningSettingsManager

    var body: some View {
        ZStack {
            if hasSeenOnboarding && surveyManager.hasCompletedSurvey && hasCompletedPermissionGate {
                AuthGateView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            } else if hasSeenOnboarding && surveyManager.hasCompletedSurvey {
                PermissionGateView {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        hasCompletedPermissionGate = true
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            } else if hasSeenOnboarding {
                OnboardingSurveyView {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        // Survey manager persists completion locally.
                    }
                }
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
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: surveyManager.hasCompletedSurvey)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: hasCompletedPermissionGate)
        .onAppear {
            guard !hasSeenOnboarding, legacyHasSeenIntro else { return }
            hasSeenOnboarding = true
            legacyHasSeenIntro = false  // Clean up legacy key after migration
        }
    }
}

struct PermissionGateView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettingsManager: LearningSettingsManager

    @State private var isRequestingPermissions = false
    @State private var localMessage: String?

    let onComplete: () -> Void

    var body: some View {
        EngifyScreenScroll(alignment: .center, spacing: Spacing.xl, bottomInset: 40) {
            VStack(spacing: Spacing.xl) {
                permissionHeader
                permissionCard
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private var permissionHeader: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.14))
                    .frame(width: 92, height: 92)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(theme.accentColor)
            }

            VStack(spacing: Spacing.sm) {
                Text("Allow Engify To Continue")
                    .font(EngifyTypography.screenTitle)
                    .foregroundStyle(EngifyColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Engify needs notifications and microphone access on first launch so reminders and speaking practice can work properly.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 20)
    }

    private var permissionCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if let localMessage, !localMessage.isEmpty {
                    StatusBanner(message: localMessage, type: .info)
                }

                permissionRow(
                    title: "Notifications",
                    subtitle: "Daily reminders and streak nudges keep your learning habit active.",
                    systemImage: "bell.badge.fill",
                    status: learningSettingsManager.notificationPermissionStatus
                )

                permissionRow(
                    title: "Microphone",
                    subtitle: "Speaking practice and pronunciation features need microphone access.",
                    systemImage: "mic.fill",
                    status: learningSettingsManager.microphonePermissionStatus
                )

                PrimaryButton(
                    title: isRequestingPermissions ? "Requesting Access..." : "Accept and Continue",
                    systemImage: "arrow.right.circle.fill",
                    action: requestRequiredPermissions,
                    isDisabled: isRequestingPermissions
                )
                .environmentObject(theme)
            }
        }
    }

    private func permissionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        status: PermissionStatus
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            EngifyIconBadge(systemImage: systemImage, tint: theme.accentColor, size: 44)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(EngifyTypography.headline)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text(subtitle)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Text(status.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(status.color)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background(status.color.opacity(0.10))
                .clipShape(Capsule())
        }
    }

    private func requestRequiredPermissions() {
        guard !isRequestingPermissions else { return }
        isRequestingPermissions = true
        localMessage = nil

        Task {
            let notificationsGranted = await learningSettingsManager.requestNotificationPermission()
            let microphoneGranted = await learningSettingsManager.requestMicrophonePermission()

            await MainActor.run {
                isRequestingPermissions = false

                if notificationsGranted && microphoneGranted {
                    EngifyFeedback.shared.play(.successPop)
                    onComplete()
                } else {
                    localMessage = "Please allow both notifications and microphone access to continue using Engify."
                }
            }
        }
    }
}

@MainActor
private func makeContentViewPreview() -> some View {
    let savedWordsManager = SavedWordsManager()
    let gamificationManager = GamificationManager()
    let surveyManager = OnboardingSurveyManager()

    return ContentView()
        .environmentObject(AuthenticationManager(
            savedWordsManager: savedWordsManager,
            gamificationManager: gamificationManager,
            surveyManager: surveyManager
        ))
        .environmentObject(savedWordsManager)
        .environmentObject(ThemeManager())
        .environmentObject(gamificationManager)
        .environmentObject(LearningSettingsManager())
        .environmentObject(surveyManager)
}

#Preview {
    makeContentViewPreview()
}
