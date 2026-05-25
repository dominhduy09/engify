import SwiftUI

struct VocabularyView: View {
    @StateObject private var dictionaryViewModel = DictionaryViewModel()
    @State private var lessonWord = "meticulous"
    @State private var currentWordIndex = 0
    @State private var wordsReviewedThisSession = 0
    @State private var savedToastWordTitle: String?
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showSettingsSheet = false
    @State private var showSavedWordBank = false

    private let lessonWords = Array(
        NSOrderedSet(array: EngifySampleData.vocabularyWords.map { $0.word.lowercased() })
    ).compactMap { $0 as? String }

    private var currentEntry: DictionaryEntry {
        dictionaryViewModel.currentEntry ?? DictionaryEntry.placeholder(for: lessonWord)
    }

    private var currentWord: Word {
        Word(
            word: currentEntry.word,
            pronunciation: currentEntry.phonetic == "N/A" ? "" : currentEntry.phonetic,
            partOfSpeech: currentEntry.partOfSpeech == "N/A" ? "N/A" : currentEntry.partOfSpeech,
            meaning: currentEntry.vietnameseMeaning,
            example: currentEntry.example
        )
    }

    var body: some View {
        EngifyScreenScroll {
            globalHeader
            wordCard
            actionButtons
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
        .task {
            await searchLessonWord()
        }
    }

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: "Vocab",
            subtitle: "Curated lesson flow with deep word focus",
            showSettings: $showSettingsSheet
        )
    }

    private var wordCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    VocabularyBadge(text: "Word #\(currentWordIndex + 1)")
                    VocabularyBadge(text: displayValue(currentEntry.partOfSpeech.capitalizedIfAvailable), tint: theme.accentColor)
                    bookmarkButton
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(displayValue(currentEntry.word))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(EngifyColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.xs) {
                        Text(displayValue(currentEntry.phonetic))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(EngifyColors.textSecondary)

                        Image(systemName: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.accentColor)
                    }
                }

                Divider()

                structuredBreakdown
                progressIndicator
            }
        }
    }

    private var structuredBreakdown: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            lessonDetailBlock(
                title: "Definition",
                icon: "list.bullet.rectangle.portrait",
                tint: theme.accentColor
            ) {
                Text(displayValue(currentEntry.definition))
            }

            lessonDetailBlock(
                title: "Vietnamese Meaning",
                icon: "globe",
                tint: EngifyColors.sage
            ) {
                Text(displayValue(currentEntry.vietnameseMeaning))
            }

            lessonDetailBlock(
                title: "Example",
                icon: "quote.opening",
                tint: EngifyColors.sky
            ) {
                Text(exampleText)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .italic()
            }
        }
    }

    private var bookmarkButton: some View {
        let isSaved = savedWordsManager.isSaved(word: currentWord)

        return Button {
            let wasSaved = isSaved
            withAnimation(EngifySpring.jellyRelease) {
                savedWordsManager.toggleSaved(word: currentWord)
            }
            EngifyFeedback.shared.play(.successPop, settings: learningSettings)
            if !wasSaved, savedWordsManager.isSaved(word: currentWord) {
                showSavedWordToast(for: currentWord.word)
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                Text("Bookmark")
            }
            .font(EngifyTypography.caption.weight(.semibold))
            .foregroundStyle(isSaved ? EngifyColors.textInverse : theme.accentColor)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 42)
            .background(
                Capsule()
                    .fill(isSaved ? theme.accentColor : theme.accentColor.opacity(0.12))
            )
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

                Text("\(min(wordsReviewedThisSession, 8))/8")
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(theme.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text("\(max(0, 8 - wordsReviewedThisSession)) more words to reach today’s target.")
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

            completeLessonButton
        }
    }

    private var skipButton: some View {
        SecondaryButton(
            title: "Skip",
            systemImage: "forward.fill",
            action: { skipWord() },
            size: .large
        )
    }

    private var nextWordButton: some View {
        PrimaryButton(
            title: "Next Word",
            systemImage: "arrow.right.circle.fill",
            action: { advanceWord() },
            size: .large,
            feedbackEvent: .tabSwitch
        )
        .environmentObject(theme)
    }

    private var completeLessonButton: some View {
        PrimaryButton(
            title: "Complete Lesson",
            systemImage: "checkmark.circle.fill",
            action: {
                gamification.earnXP(10)
                EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
            },
            size: .large,
            feedbackEvent: .successPop
        )
        .environmentObject(theme)
    }

    private var exampleText: String {
        let example = displayValue(currentEntry.example)
        return example == "N/A" ? "N/A" : "“\(example)”"
    }

    private func lessonDetailBlock<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            content()
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func advanceWord() {
        wordsReviewedThisSession += 1
        guard !lessonWords.isEmpty else { return }
        currentWordIndex = (currentWordIndex + 1) % lessonWords.count
        lessonWord = lessonWords[currentWordIndex]
        Task {
            await searchLessonWord()
        }
        gamification.earnXP(5)
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func skipWord() {
        guard !lessonWords.isEmpty else { return }
        currentWordIndex = (currentWordIndex + 1) % lessonWords.count
        lessonWord = lessonWords[currentWordIndex]
        Task {
            await searchLessonWord()
        }
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func searchLessonWord() async {
        if lessonWords.isEmpty {
            dictionaryViewModel.currentEntry = DictionaryEntry.placeholder(for: "N/A")
            return
        }

        lessonWord = lessonWords[currentWordIndex]
        dictionaryViewModel.searchText = lessonWord
        await dictionaryViewModel.search()
    }

    private func displayValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "N/A" : value
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
