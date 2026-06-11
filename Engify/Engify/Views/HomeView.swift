import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: EngifyTab
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @State private var showSettingsSheet = false
    @State private var showTutorSheet = false
    @State private var dailyQuote: QuoteService.DailyQuote?
    @State private var dailyTip: LearningTip = LearningTip.tipOfTheDay()

    var body: some View {
        EngifyScreenScroll {
            globalHeader
            dailyQuoteCard
            dailyTipCard
            tutorSection
            continueLearningSection
            lookupSection
            newsAndReadingSection
            practiceSection
            recommendedSection
            recentActivitySection
        }
        .engifySettingsSheet(isPresented: $showSettingsSheet)
        .sheet(isPresented: $showTutorSheet) {
            if #available(iOS 16.0, *) {
                NavigationView {
                    EngifyTutorSheet()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            } else {
                NavigationView {
                    EngifyTutorSheet()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .task {
            let service = QuoteService()
            dailyQuote = await service.fetchDailyQuote()
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

    private var tutorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "Engify Tutor",
                subtitle: "Ask for explanations, examples, corrections, and a calm next step whenever you feel stuck."
            )

            EngifyFeatureButton(
                title: "Chat With Engify Tutor",
                subtitle: "Open your tutor assistant for grammar help, study plans, and guided speaking support.",
                systemImage: "bubble.left.and.bubble.right.fill"
            ) {
                showTutorSheet = true
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

private struct EngifyTutorMessage: Identifiable, Hashable {
    enum Role {
        case tutor
        case learner
    }

    let id = UUID()
    let role: Role
    let text: String
}

private struct EngifyTutorSheet: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @State private var draftMessage = ""
    @State private var messages: [EngifyTutorMessage] = [
        EngifyTutorMessage(
            role: .tutor,
            text: "Hi, I'm Engify Tutor. Tell me what you want to improve, and I'll help with explanations, examples, or a short practice plan."
        )
    ]

    private let starterPrompts = [
        "Explain present simple",
        "Help me describe a picture",
        "Correct my sentence",
        "Make a 10-minute study plan"
    ]

    var body: some View {
        EngifyScreenScroll(bottomInset: 120) {
            tutorHeader
            starterPromptSection
            conversationSection
        }
        .navigationTitle("Engify Tutor")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            tutorComposer
                .background(EngifyColors.canvas.opacity(0.96))
        }
    }

    private var tutorHeader: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    EngifyIconBadge(systemImage: "brain.head.profile", tint: theme.accentColor, size: 58)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Engify Tutor")
                            .font(EngifyTypography.screenTitle)
                            .foregroundStyle(EngifyColors.textPrimary)

                        Text("Your built-in tutor assistant for grammar, speaking, vocabulary, and study guidance.")
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: Spacing.sm) {
                    VocabularyBadge(text: learningSettings.explanationDepth.capitalized, tint: theme.accentColor)
                    VocabularyBadge(text: learningSettings.correctionStyle.capitalized, tint: theme.accentColor)
                    VocabularyBadge(text: learningSettings.learningGoal.capitalized, tint: theme.accentColor)
                }
            }
        }
    }

    private var starterPromptSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "Quick Starts",
                subtitle: "Tap a prompt if you want a fast nudge."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(starterPrompts, id: \.self) { prompt in
                        Button {
                            send(prompt)
                        } label: {
                            VocabularyBadge(text: prompt, tint: theme.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifySectionHeader(
                title: "Conversation",
                subtitle: "Ask naturally. Engify Tutor will respond in your selected tutoring style."
            )

            VStack(spacing: Spacing.md) {
                ForEach(messages) { message in
                    tutorBubble(for: message)
                }
            }
        }
    }

    private func tutorBubble(for message: EngifyTutorMessage) -> some View {
        HStack {
            if message.role == .tutor {
                bubbleView(
                    text: message.text,
                    tint: theme.accentColor.opacity(0.12),
                    foreground: EngifyColors.textPrimary,
                    alignment: .leading,
                    icon: "brain.head.profile",
                    iconTint: theme.accentColor
                )
                Spacer(minLength: 32)
            } else {
                Spacer(minLength: 32)
                bubbleView(
                    text: message.text,
                    tint: theme.accentColor,
                    foreground: EngifyColors.textInverse,
                    alignment: .trailing,
                    icon: "person.fill",
                    iconTint: EngifyColors.textInverse
                )
            }
        }
    }

    private func bubbleView(
        text: String,
        tint: Color,
        foreground: Color,
        alignment: HorizontalAlignment,
        icon: String,
        iconTint: Color
    ) -> some View {
        VStack(alignment: alignment, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                if alignment == .leading {
                    EngifyIconBadge(systemImage: icon, tint: iconTint, size: 34)
                }

                Text(text)
                    .font(EngifyTypography.body)
                    .foregroundStyle(foreground)
                    .fixedSize(horizontal: false, vertical: true)

                if alignment == .trailing {
                    EngifyIconBadge(systemImage: icon, tint: theme.accentColor.opacity(0.24), size: 34)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(tint)
            )
        }
    }

    private var tutorComposer: some View {
        VStack(spacing: Spacing.sm) {
            Divider()

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                if #available(iOS 16.0, *) {
                    TextField("Ask Engify Tutor anything...", text: $draftMessage, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled()
                        .font(EngifyTypography.body)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(EngifyColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(theme.accentColor.opacity(0.12), lineWidth: 1)
                        )
                } else {
                    // Fallback on earlier versions
                }

                Button {
                    sendCurrentDraft()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(EngifyColors.textInverse)
                        .frame(width: 48, height: 48)
                        .background(theme.accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(trimmedDraft.isEmpty)
                .opacity(trimmedDraft.isEmpty ? 0.45 : 1)
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
    }

    private var trimmedDraft: String {
        draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sendCurrentDraft() {
        let message = trimmedDraft
        guard !message.isEmpty else { return }
        draftMessage = ""
        send(message)
    }

    private func send(_ prompt: String) {
        let cleaned = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        withAnimation(EngifySpring.jellyRelease) {
            messages.append(EngifyTutorMessage(role: .learner, text: cleaned))
            messages.append(EngifyTutorMessage(role: .tutor, text: tutorReply(to: cleaned)))
        }

        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func tutorReply(to prompt: String) -> String {
        let lowercasedPrompt = prompt.lowercased()

        if lowercasedPrompt.contains("grammar") || lowercasedPrompt.contains("present simple") {
            return grammarReply(for: prompt)
        }

        if lowercasedPrompt.contains("picture") || lowercasedPrompt.contains("image") || lowercasedPrompt.contains("describe") {
            return imageReply(for: prompt)
        }

        if lowercasedPrompt.contains("study plan") || lowercasedPrompt.contains("plan") {
            return studyPlanReply()
        }

        if lowercasedPrompt.contains("correct") || lowercasedPrompt.contains("sentence") {
            return correctionReply(for: prompt)
        }

        return generalReply(for: prompt)
    }

    private func grammarReply(for prompt: String) -> String {
        switch learningSettings.explanationDepth {
        case "detailed":
            return "Engify Tutor: \(prompt) usually works best when we break it into rule, pattern, and example. Start with one clear sentence pattern, then make two personal examples about your daily life so the rule becomes active, not just memorized."
        case "simple":
            return "Engify Tutor: Keep it simple. Learn one rule, read one example, then say your own sentence out loud."
        default:
            return "Engify Tutor: Focus on one grammar rule at a time, then build one short sentence about yourself to lock it in."
        }
    }

    private func imageReply(for prompt: String) -> String {
        let tone: String
        switch learningSettings.correctionStyle {
        case "strict":
            tone = "Be precise: name people, actions, objects, and mood."
        case "gentle":
            tone = "Start with easy details first, then add color, action, and feeling."
        default:
            tone = "Describe the scene step by step so your English stays natural."
        }

        return "Engify Tutor: For '\(prompt)', try this order: what you see, what is happening, and why the scene feels that way. \(tone)"
    }

    private func studyPlanReply() -> String {
        let minutes = max(10, learningSettings.newWordsPerDay)
        return "Engify Tutor: Try a short daily plan. Spend 3 minutes on review, 4 minutes on one focused lesson, and 3 minutes speaking or writing. If you want more challenge, add \(minutes / 2) extra minutes for vocabulary recall."
    }

    private func correctionReply(for prompt: String) -> String {
        switch learningSettings.correctionStyle {
        case "strict":
            return "Engify Tutor: I'll be direct. Keep the sentence short, check verb tense, and remove extra words. Send me one exact sentence next and I'll help tighten it."
        case "gentle":
            return "Engify Tutor: You're close. Send me the sentence you want help with, and I'll correct it softly with a clearer version."
        default:
            return "Engify Tutor: Send me the sentence exactly as you wrote it, and I'll show you a clearer corrected version."
        }
    }

    private func generalReply(for prompt: String) -> String {
        let goal = learningSettings.learningGoal.capitalized
        return "Engify Tutor: I can help with that. Since your current learning goal is \(goal), let's keep this practical. We can explain the idea, make one example, and end with one small practice step based on '\(prompt)'."
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
