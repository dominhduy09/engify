import SwiftUI

struct HomeView: View {
    private enum HomeDestination: Identifiable {
        case news
        case practice

        var id: String {
            switch self {
            case .news: return "news"
            case .practice: return "practice"
            }
        }
    }

    @Binding var selectedTab: EngifyTab
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @State private var showSettingsSheet = false
    @State private var activeDestination: HomeDestination?

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
        .sheet(item: $activeDestination) { destination in
            NavigationView {
                destinationView(for: destination)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                activeDestination = nil
                            }
                        }
                    }
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
                activeDestination = .news
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
                activeDestination = .practice
            }
        }
    }

    private var continueLearningSection: some View {
        PrimaryButton(title: "Continue Learning", systemImage: "play.fill", action: {
            selectedTab = .vocabulary
        })
        .environmentObject(theme)
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "Recommended",
                subtitle: "Helpful next steps tailored to your daily routine."
            )

            EngifyFeatureButton(
                title: "Travel Vocabulary",
                subtitle: "A focused session with practical words you can use right away.",
                systemImage: "book.fill"
            ) {
                selectedTab = .vocabulary
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

    @ViewBuilder
    private func destinationView(for destination: HomeDestination) -> some View {
        switch destination {
        case .news:
            NewsReadingView()
        case .practice:
            PracticeView()
        }
    }
}
