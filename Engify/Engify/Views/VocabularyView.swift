import SwiftUI

struct VocabularyView: View {
    @State private var currentWord: Word
    @State private var previousWords: [String] = []
    @State private var cardRotation: Double = 0
    @State private var wordsReviewedThisSession = 0
    @State private var showLessonComplete = false
    @State private var savedToastWordTitle: String?
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showSettingsSheet = false
    @State private var showSavedWordBank = false

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
            globalHeader
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
        .overlay(alignment: .top) {
            if let savedToastWordTitle {
                savedWordToast(wordTitle: savedToastWordTitle)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .scale(scale: 0.92)).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .engifySettingsSheet(isPresented: $showSettingsSheet)
        .sheet(isPresented: $showSavedWordBank) {
            SavedWordBankSheet()
                .environmentObject(savedWordsManager)
        }
    }

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: "Vocab",
            subtitle: "New words, tighter focus",
            showSettings: $showSettingsSheet
        )
    }
    private var wordCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    cardMeta
                    saveButton
                    Spacer(minLength: 0)
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
            let wasSaved = savedWordsManager.isSaved(word: currentWord)
            withAnimation(EngifySpring.jellyRelease) {
                savedWordsManager.toggleSaved(word: currentWord)
            }
            EngifyFeedback.shared.play(.successPop, settings: learningSettings)
            if !wasSaved, savedWordsManager.isSaved(word: currentWord) {
                showSavedWordToast(for: currentWord.word)
            }
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
            .drawingGroup()
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }

    private func savedWordToast(wordTitle: String) -> some View {
        Button {
            withAnimation(EngifySpring.jellyRelease) {
                savedToastWordTitle = nil
                showSavedWordBank = true
            }
            EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: "bookmark.circle.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.accentColor)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Saved to Word Bank")
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text("\"\(wordTitle)\" is ready to review. Tap to open.")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.accentColor)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(EngifyColors.surface.opacity(0.97))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(theme.accentColor.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: EngifyColors.primary.opacity(0.12), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }

    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Daily Goal")
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                Spacer(minLength: 0)
                Text("\(min(wordsReviewedThisSession, learningSettings.newWordsPerDay))/\(learningSettings.newWordsPerDay)")
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(theme.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(goalProgressSubtitle)
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
                gamification.completeLesson(type: .vocabulary, xpEarned: 10)
                showLessonComplete = true
                advanceWord(triggerFeedback: false)
            }, feedbackEvent: .successPop)
            .environmentObject(theme)
        }
    }

    private var goalProgressSubtitle: String {
        if wordsReviewedThisSession >= learningSettings.newWordsPerDay {
            return "You reached today’s vocabulary target. Keep going if you want extra practice."
        }

        let remaining = max(0, learningSettings.newWordsPerDay - wordsReviewedThisSession)
        return "\(remaining) more word\(remaining == 1 ? "" : "s") to reach today’s target."
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

    private func advanceWord(triggerFeedback: Bool = true) {
        wordsReviewedThisSession += 1
        if wordsReviewedThisSession % 5 == 0 {
            gamification.earnXP(5)
        }

        withAnimation(EngifySpring.tabSlide) {
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

        if triggerFeedback {
            EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
        }
    }

    private func skipWord() {
        withAnimation(EngifySpring.tabSlide) {
            currentWord = EngifySampleData.vocabularyWords.randomElement() ?? currentWord
            cardRotation += 360
        }

        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func showSavedWordToast(for wordTitle: String) {
        withAnimation(EngifySpring.jellyRelease) {
            savedToastWordTitle = wordTitle
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard savedToastWordTitle == wordTitle else { return }

            await MainActor.run {
                withAnimation(EngifySpring.settle) {
                    savedToastWordTitle = nil
                }
            }
        }
    }
}
