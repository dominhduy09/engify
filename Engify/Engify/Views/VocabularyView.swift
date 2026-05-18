import SwiftUI

struct VocabularyView: View {
    @State private var currentWord: Word
    @State private var previousWords: [String] = []
    @State private var cardRotation: Double = 0
    @State private var wordsReviewedThisSession = 0
    @State private var showLessonComplete = false
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isHeaderExpanded = false
    @State private var showSettingsSheet = false

    init() {
        let initialWord = EngifySampleData.vocabularyWords.randomElement()
            ?? EngifySampleData.vocabularyWords.first
            ?? Word(
                word: "learn",
                pronunciation: "/lɝn/",
                partOfSpeech: "verb",
                meaning: "hoc",
                example: "We learn a little every day."
            )
        _currentWord = State(initialValue: initialWord)
    }

    var body: some View {
        EngifyScreenScroll {
            topHeaderBar
            EngifyTopMetricsBar()
            headerSection
            wordCard
            actionButtons
        }
        .refreshable {
            advanceWord()
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        .tabTransition()
        .overlay {
            if showLessonComplete {
                LessonCompleteOverlay()
                    .environmentObject(gamification)
            }
        }
        .overlay(alignment: .bottom) {
            if gamification.showXPGain {
                XPGainToast(amount: gamification.lastXPGained)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .engifySettingsSheet(isPresented: $showSettingsSheet)
    }

    private var topHeaderBar: some View {
        EngifyTopHeaderBar(
            title: "Vocabulary",
            subtitle: "New words, tighter focus",
            showSettings: $showSettingsSheet
        )
    }

    private var headerSection: some View {
        let config = TabHeaderConfig.vocabulary
        return EngifyCollapsibleCard(
            title: config.title,
            subtitle: config.subtitle,
            systemImage: config.icon,
            tint: config.primaryColor,
            isExpanded: $isHeaderExpanded
        ) {
            HStack(spacing: Spacing.sm) {
                VocabularyBadge(text: "Session \(wordsReviewedThisSession + 1)", tint: config.primaryColor)
                VocabularyBadge(text: "Tap to review", tint: config.secondaryColor)
                Spacer(minLength: 0)
            }
        } detail: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Build your vocabulary one word at a time with quick meanings, examples, and save actions that stay easy to scan.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                LinearGradient(
                    colors: [config.primaryColor.opacity(0.28), config.secondaryColor.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
        }
    }

    private var wordCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                if horizontalSizeClass == .compact {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        cardMeta
                        saveButton
                    }
                } else {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        cardMeta
                        Spacer(minLength: 0)
                        saveButton
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(currentWord.word)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(EngifyColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(currentWord.pronunciation)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(EngifyColors.textSecondary)
                }
                .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))

                Divider()

                detailsSection
                progressIndicator
            }
        }
    }

    private var cardMeta: some View {
        HStack(spacing: Spacing.sm) {
            VocabularyBadge(text: "Word #\(wordsReviewedThisSession + 1)")
            VocabularyBadge(text: currentWord.partOfSpeech.capitalized, tint: theme.accentColor)
            Spacer(minLength: 0)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Vietnamese meaning")
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)

                Text(currentWord.meaning)
                    .font(EngifyTypography.cardTitle)
                    .foregroundStyle(EngifyColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Example")
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)

                Text("“\(currentWord.example)”")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(EngifyColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var saveButton: some View {
        Button {
            savedWordsManager.toggleSaved(word: currentWord)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: savedWordsManager.isSaved(word: currentWord) ? "bookmark.fill" : "bookmark")
                Text(savedWordsManager.isSaved(word: currentWord) ? "Saved" : "Save")
            }
            .font(EngifyTypography.caption.weight(.semibold))
            .foregroundStyle(savedWordsManager.isSaved(word: currentWord) ? theme.accentColor : EngifyColors.textSecondary)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 42)
            .background((savedWordsManager.isSaved(word: currentWord) ? theme.accentColor : EngifyColors.border).opacity(0.14))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Unlimited Vocabulary")
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                Spacer(minLength: 0)
                Image(systemName: "infinity")
                    .font(.caption)
                    .foregroundStyle(theme.accentColor)
            }

            Text("Tap next to keep exploring fresh words without losing your rhythm.")
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            if horizontalSizeClass == .compact {
                VStack(spacing: Spacing.md) {
                    skipButton
                    nextWordButton
                }
            } else {
                HStack(spacing: Spacing.md) {
                    skipButton
                    nextWordButton
                }
            }

            PrimaryButton(title: "Complete Lesson", systemImage: "checkmark.circle.fill", action: {
                advanceWord()
                gamification.completeLesson(type: .vocabulary, xpEarned: 10)
                showLessonComplete = true
            })
            .environmentObject(theme)
        }
    }

    private var skipButton: some View {
        SecondaryButton(title: "Skip", systemImage: "xmark", action: {
            skipWord()
        })
    }

    private var nextWordButton: some View {
        PrimaryButton(title: "Next Word", systemImage: "arrow.right", action: {
            advanceWord()
        })
        .environmentObject(theme)
    }

    private func advanceWord() {
        wordsReviewedThisSession += 1
        if wordsReviewedThisSession % 5 == 0 {
            gamification.earnXP(5)
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let availableWords = EngifySampleData.vocabularyWords.filter { !previousWords.contains($0.word) }
            let nextWord: Word

            if availableWords.isEmpty {
                previousWords.removeAll()
                nextWord = EngifySampleData.vocabularyWords.randomElement() ?? currentWord
            } else {
                nextWord = availableWords.randomElement() ?? currentWord
            }

            previousWords.append(currentWord.word)
            if previousWords.count > 10 {
                previousWords.removeFirst()
            }

            currentWord = nextWord
            cardRotation += 360
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func skipWord() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentWord = EngifySampleData.vocabularyWords.randomElement() ?? currentWord
            cardRotation += 360
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
