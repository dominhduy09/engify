import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: EngifyTab
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @State private var showSettingsSheet = false

    var body: some View {
        EngifyScreenScroll {
            globalHeader
            continueLearningSection
            newsAndReadingSection
            practiceSection
            recommendedSection
            recentActivitySection
        }
        .engifySettingsSheet(isPresented: $showSettingsSheet)
        .overlay {
            if gamification.showLessonComplete {
                LessonCompleteOverlay()
                    .environmentObject(gamification)
            }
        }
    }

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: "Home",
            subtitle: "Daily rhythm and quick wins",
            showSettings: $showSettingsSheet
        )
    }

    private var newsAndReadingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "News & Reading",
                subtitle: "Short articles and guided reading practice with the same green visual language."
            )

            EngifyFeatureButton(
                title: "Daily Reading Brief",
                subtitle: "Open a compact reading session with approachable stories and useful vocabulary cues.",
                systemImage: "newspaper.fill"
            ) {
                navigate(to: .news)
            }
        }
    }

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "Practice",
                subtitle: "Jump into active speaking, grammar, and quiz work without leaving the home flow."
            )

            EngifyFeatureButton(
                title: "Quick Practice Sprint",
                subtitle: "Launch a short grammar and speaking session designed for a few focused minutes.",
                systemImage: "sparkles"
            ) {
                navigate(to: .practice)
            }
        }
    }

    private var continueLearningSection: some View {
        PrimaryButton(title: "Continue Learning", systemImage: "play.fill", action: {
            if authManager.isGuestMode {
                authManager.presentAccountRequired(for: .vocabulary)
            } else {
                navigate(to: .vocabulary)
            }
        }, feedbackEvent: authManager.isGuestMode ? .errorBuzz : .tabSwitch)
        .environmentObject(theme)
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "Recommended",
                subtitle: "Helpful next steps tailored to your daily routine."
            )

            EngifyFeatureButton(
                title: recommendedFeature.title,
                subtitle: recommendedFeature.subtitle,
                systemImage: recommendedFeature.systemImage
            ) {
                if authManager.isGuestMode, recommendedFeature.requiresAccount {
                    authManager.presentAccountRequired(for: .vocabulary)
                } else {
                    navigate(to: recommendedFeature.tab)
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "Recent Activity",
                subtitle: "A quick look at the habits you’ve built."
            )

            VStack(spacing: Spacing.md) {
                activityRow(
                    icon: "book.fill",
                    iconColor: EngifyColors.sage,
                    title: "Reviewed Essential Verbs",
                    subtitle: "2 days ago"
                )

                activityRow(
                    icon: "newspaper.fill",
                    iconColor: EngifyColors.sky,
                    title: "Read Climate News",
                    subtitle: "4 days ago"
                )

                activityRow(
                    icon: "pencil.circle.fill",
                    iconColor: theme.accentColor,
                    title: "Practiced Grammar Quiz",
                    subtitle: "1 week ago"
                )
            }
        }
    }

    private func activityRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        EngifyCard(tint: iconColor) {
            HStack(spacing: Spacing.md) {
                EngifyIconBadge(systemImage: icon, tint: iconColor, size: 44)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(subtitle)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func navigate(to tab: EngifyTab) {
        withAnimation(EngifySpring.tabSlide) {
            selectedTab = tab
        }
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private var recommendedFeature: (title: String, subtitle: String, systemImage: String, tab: EngifyTab, requiresAccount: Bool) {
        switch learningSettings.learningGoal {
        case "travel":
            return (
                title: "Travel Vocabulary",
                subtitle: "A focused session with practical words you can use right away.",
                systemImage: "airplane",
                tab: .vocabulary,
                requiresAccount: true
            )
        case "work":
            return (
                title: "Workplace Reading",
                subtitle: "Practice with current articles and vocabulary that feels useful at work.",
                systemImage: "briefcase.fill",
                tab: .news,
                requiresAccount: false
            )
        case "study":
            return (
                title: "Dictionary Deep Dive",
                subtitle: "Look up precise meanings and examples to support stronger reading.",
                systemImage: "text.book.closed.fill",
                tab: .dictionary,
                requiresAccount: false
            )
        case "exam":
            return (
                title: "Quick Quiz Arena",
                subtitle: "Train accuracy and response speed with short exam-style checks.",
                systemImage: "checklist.checked",
                tab: .practice,
                requiresAccount: true
            )
        default:
            return (
                title: "Daily Vocabulary",
                subtitle: "A compact word session that matches your everyday communication goal.",
                systemImage: "book.fill",
                tab: .vocabulary,
                requiresAccount: true
            )
        }
    }
}
