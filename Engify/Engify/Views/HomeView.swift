import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: EngifyTab
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @State private var showSettingsSheet = false
    @State private var dailyQuote: QuoteService.DailyQuote?
    @State private var dailyTip: LearningTip = LearningTip.tipOfTheDay()

    var body: some View {
        EngifyScreenScroll {
            globalHeader
            dailyQuoteCard
            dailyTipCard
            continueLearningSection
            lookupSection
            newsAndReadingSection
            practiceSection
            recommendedSection
            recentActivitySection
        }
        .engifySettingsSheet(isPresented: $showSettingsSheet)
        .task {
            let service = QuoteService()
            dailyQuote = await service.fetchDailyQuote()
        }
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

    private var lookupSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "Lookup",
                subtitle: "Jump straight into the dictionary to check meanings, pronunciation, and examples."
            )

            EngifyFeatureButton(
                title: "Open Dictionary Lookup",
                subtitle: "Search any word quickly and review the definition in one place.",
                systemImage: "magnifyingglass"
            ) {
                navigate(to: .dictionary)
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
        Group {
            if !recentActivities.isEmpty {
                VStack(spacing: Spacing.md) {
                    EngifySectionHeader(
                        title: "Recent Activity",
                        subtitle: "A quick look at the habits you’ve built."
                    )

                    VStack(spacing: Spacing.md) {
                        ForEach(recentActivities) { activity in
                            activityRow(
                                icon: activity.icon,
                                iconColor: activity.iconColor,
                                title: activity.title,
                                subtitle: activity.subtitle
                            )
                        }
                    }
                }
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

    private var recentActivities: [RecentActivityItem] {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        var items = gamification.recentLessonResults.prefix(6).map { result in
            RecentActivityItem(
                icon: result.lessonType.activityIcon,
                iconColor: result.lessonType.activityColor(themeAccent: theme.accentColor),
                title: result.lessonType.activityTitle,
                subtitle: formatter.localizedString(for: result.completedAt, relativeTo: Date()),
                timestamp: result.completedAt
            )
        }

        if let savedWordEvent = savedWordsManager.lastSavedWordEvent {
            items.append(
                RecentActivityItem(
                    icon: savedWordEvent.activityIcon,
                    iconColor: savedWordEvent.activityColor(themeAccent: theme.accentColor),
                    title: savedWordEvent.activityTitle,
                    subtitle: "Just now",
                    timestamp: Date()
                )
            )
        }

        var seenTitles = Set<String>()

        return items
            .sorted { $0.timestamp > $1.timestamp }
            .filter { activity in
                seenTitles.insert(activity.title).inserted
            }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Daily Quote Card

    private var dailyQuoteCard: some View {
        Group {
            if let quote = dailyQuote {
                EngifyCard(tint: theme.accentColor) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "quote.opening")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(theme.accentColor)

                            Text("Quote of the Day")
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

                            Spacer()

                            Text("Daily")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(EngifyColors.textInverse)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(theme.accentColor)
                                .clipShape(Capsule())
                        }

                        if #available(iOS 16.0, *) {
                            Text("\u{201C}\(quote.text)\u{201D}")
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundStyle(EngifyColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .italic()
                        } else {
                            // Fallback on earlier versions
                        }

                        Text("\u{2014} \(quote.author)")
                            .font(EngifyTypography.caption.weight(.semibold))
                            .foregroundStyle(EngifyColors.textSecondary)
                    }
                }
            } else {
                // Shimmer placeholder while loading
                EngifyCard(tint: theme.accentColor) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "quote.opening")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(theme.accentColor)

                            Text("Quote of the Day")
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

                            Spacer()
                        }

                        RoundedRectangle(cornerRadius: 6)
                            .fill(EngifyColors.border.opacity(0.3))
                            .frame(height: 44)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(EngifyColors.border.opacity(0.2))
                            .frame(width: 120, height: 14)
                    }
                }
            }
        }
    }

    // MARK: - Daily Tip Card

    private var dailyTipCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: dailyTip.icon)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.accentColor)

                    Text("Tip of the Day")
                        .font(EngifyTypography.headline)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Spacer()

                    Text(dailyTip.category)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(EngifyColors.textInverse)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.accentColor)
                        .clipShape(Capsule())
                }

                Text(dailyTip.title)
                    .font(EngifyTypography.bodyStrong)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text(dailyTip.body)
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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

private struct RecentActivityItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let timestamp: Date
}

private extension LessonType {
    var activityIcon: String {
        switch self {
        case .vocabulary:
            return "book.fill"
        case .practice:
            return "pencil.circle.fill"
        case .dictionary:
            return "magnifyingglass"
        case .news:
            return "newspaper.fill"
        }
    }

    func activityColor(themeAccent: Color) -> Color {
        themeAccent
    }

    var activityTitle: String {
        switch self {
        case .vocabulary:
            return "Completed a vocabulary lesson"
        case .practice:
            return "Finished a practice session"
        case .dictionary:
            return "Used dictionary lookup"
        case .news:
            return "Completed a news reading lesson"
        }
    }
}

private extension SavedWordEvent {
    var activityIcon: String {
        switch self {
        case .dictionary:
            return "bookmark.fill"
        case .vocabulary:
            return "bookmark.circle.fill"
        }
    }

    func activityColor(themeAccent: Color) -> Color {
        themeAccent
    }

    var activityTitle: String {
        switch self {
        case let .dictionary(entry):
            return "Saved \(entry.word) from Dictionary"
        case let .vocabulary(word):
            return "Saved \(word.word) to Vocabulary"
        }
    }
}
