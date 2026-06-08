import AVFoundation
import SwiftUI

struct VocabularyView: View {
    private enum ReviewMode: String, CaseIterable, Identifiable {
        case hidden
        case showing

        var id: String { rawValue }
    }

    private enum StorageKeys {
        static let completedVocabularyWords = "engify.vocabulary.completed-words"
        static let reviewVocabularyWords = "engify.vocabulary.review-words"
    }

    @StateObject private var dictionaryViewModel = DictionaryViewModel()
    @State private var lessonWord = "habit"
    @State private var lessonWords: [String] = []
    @State private var wordsReviewedThisSession = 0
    @State private var savedToastWordTitle: String?
    @State private var isLoadingNewWords = false
    @State private var reviewWords: [Word] = []
    @State private var completedWordIDs: Set<String> = []
    @State private var completedCurrentWordIDs: Set<String> = []
    @State private var reviewMode: ReviewMode = .hidden
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @EnvironmentObject private var surveyManager: OnboardingSurveyManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showSettingsSheet = false
    @State private var showSavedWordBank = false
    @State private var audioPlayer: AVPlayer?

    private let randomWordService = DictionaryService()

    private let fallbackLessonWords = Array(
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
            meaning: preferredMeaning(for: currentEntry),
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
            await initializeVocabularyExperience()
        }
    }

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: "Vocab",
            subtitle: "Fresh API words with a review deck that remembers your progress",
            showSettings: $showSettingsSheet
        )
    }

    private var wordCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    VocabularyBadge(text: currentWordBadgeText)
                    VocabularyBadge(text: displayValue(currentEntry.partOfSpeech.capitalizedIfAvailable), tint: theme.accentColor)
                    if displayValue(currentEntry.category) != "N/A" {
                        VocabularyBadge(text: displayValue(currentEntry.category), tint: theme.accentColor)
                    }
                    if displayValue(currentEntry.wordLevel) != "N/A" {
                        VocabularyBadge(text: displayValue(currentEntry.wordLevel), tint: theme.accentColor)
                    }
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

                        Button {
                            playAudioForCurrentWord()
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                structuredBreakdown
                progressIndicator
                if isLoadingNewWords {
                    loadingWordsState
                }
            }
        }
    }

    private var structuredBreakdown: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if learningSettings.explanationDepth != "simple" {
                lessonDetailBlock(
                    title: "Tutor Note",
                    icon: "sparkles",
                    tint: theme.accentColor
                ) {
                    Text(tutorNote(for: currentEntry))
                }
            }

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
                tint: theme.accentColor
            ) {
                Text(displayValue(preferredMeaning(for: currentEntry)))
            }

            lessonDetailBlock(
                title: "Example",
                icon: "quote.opening",
                tint: theme.accentColor
            ) {
                Text(exampleText)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .italic()
            }

            if displayValue(currentEntry.idiom) != "N/A" {
                lessonDetailBlock(
                    title: "Idiom",
                    icon: "text.quote",
                    tint: theme.accentColor
                ) {
                    Text(displayValue(currentEntry.idiom))
                }
            }

            if !currentEntry.phrasalVerbs.isEmpty {
                lessonDetailBlock(
                    title: "Phrasal Verbs",
                    icon: "arrow.triangle.branch",
                    tint: theme.accentColor
                ) {
                    Text(currentEntry.phrasalVerbs.joined(separator: ", "))
                }
            }

            if learningSettings.generateExtraExamples {
                lessonDetailBlock(
                    title: "Extra Examples",
                    icon: "text.quote",
                    tint: theme.accentColor
                ) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(extraExamples(for: currentEntry), id: \.self) { example in
                            Text(example)
                        }
                    }
                }
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
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSaved ? EngifyColors.textInverse : theme.accentColor)
            .frame(width: 42, height: 42)
            .background(
                Circle()
                    .fill(isSaved ? theme.accentColor : theme.accentColor.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
        .accessibilityLabel(isSaved ? "Remove bookmark" : "Save word")
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

            Text("\(max(0, learningSettings.newWordsPerDay - wordsReviewedThisSession)) more words to reach today’s target.")
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if learningSettings.difficultyLock {
                Text(difficultyLockSummary)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
            reviewSection
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
                completeCurrentLesson()
                EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
            },
            size: .large,
            feedbackEvent: .successPop
        )
        .environmentObject(theme)
    }

    private var reviewSection: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Review")
                            .font(EngifyTypography.sectionTitle)
                            .foregroundStyle(EngifyColors.textPrimary)

                        Text(reviewSummaryText)
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    if !reviewWords.isEmpty {
                        Button(reviewMode == .showing ? "Hide" : "Open") {
                            withAnimation(EngifySpring.jellyRelease) {
                                reviewMode = reviewMode == .showing ? .hidden : .showing
                            }
                        }
                        .font(EngifyTypography.caption.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                    }
                }

                if reviewWords.isEmpty {
                    Text("Complete a lesson to save that word here for spaced review later.")
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if reviewMode == .showing {
                    VStack(spacing: Spacing.sm) {
                        ForEach(displayedReviewWords) { word in
                            reviewCard(for: word)
                        }
                    }
                }
            }
        }
    }

    private var exampleText: String {
        let example = displayValue(currentEntry.example)
        return example == "N/A" ? "N/A" : "“\(example)”"
    }

    private var currentWordBadgeText: String {
        let completedCount = completedWordIDs.count
        if completedCount == 0 {
            return "Fresh Word"
        }
        return "Fresh Word #\(completedCount + 1)"
    }

    private var reviewSummaryText: String {
        let limit = min(learningSettings.reviewLimitPerDay, reviewWords.count)
        guard !reviewWords.isEmpty else {
            return "Your completed lesson words will build a personal review list."
        }
        return "\(reviewWords.count) saved word\(reviewWords.count == 1 ? "" : "s"), showing up to \(limit) today."
    }

    private var displayedReviewWords: [Word] {
        Array(reviewWords.prefix(learningSettings.reviewLimitPerDay))
    }

    private var loadingWordsState: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(theme.accentColor)

            Text("Pulling more words from the API...")
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
        }
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
        Task {
            await moveToNextWord(countAsReviewed: true)
        }
        gamification.earnXP(5)
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func skipWord() {
        Task {
            await moveToNextWord(countAsReviewed: false)
        }
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func searchLessonWord() async {
        if lessonWords.isEmpty {
            dictionaryViewModel.currentEntry = DictionaryEntry.placeholder(for: "N/A")
            return
        }

        lessonWord = lessonWords[0]
        dictionaryViewModel.searchText = lessonWord
        await dictionaryViewModel.search()
        if learningSettings.repeatPronunciation {
            playAudioForCurrentWord()
        }
    }

    private func moveToNextWord(countAsReviewed: Bool) async {
        if countAsReviewed {
            wordsReviewedThisSession += 1
        }

        if !lessonWords.isEmpty {
            lessonWords.removeFirst()
        }

        if lessonWords.isEmpty {
            await refillLessonWordsIfNeeded(force: true)
        }

        await searchLessonWord()
        await refillLessonWordsIfNeeded()
    }

    private func completeCurrentLesson() {
        let normalized = normalizedWordID(for: currentWord.word)
        guard !normalized.isEmpty, normalized != "n/a" else { return }

        let wasNewCompletion = completedWordIDs.insert(normalized).inserted
        if wasNewCompletion {
            persistCompletedWordIDs()
        }

        saveWordForReview(currentWord)
        completedCurrentWordIDs.insert(normalized)
        gamification.completeLesson(type: .vocabulary, xpEarned: 10)
        _ = gamification.awardPoints(for: .savedWord(wordID: normalized))

        Task {
            await moveToNextWord(countAsReviewed: false)
        }
    }

    private func saveWordForReview(_ word: Word) {
        let normalized = normalizedWordID(for: word.word)
        reviewWords.removeAll { normalizedWordID(for: $0.word) == normalized }
        reviewWords.insert(word, at: 0)
        persistReviewWords()

        if reviewMode == .hidden {
            reviewMode = .showing
        }
    }

    private func refillLessonWordsIfNeeded(force: Bool = false) async {
        let bufferTarget = max(3, min(learningSettings.newWordsPerDay, 8))
        guard force || lessonWords.count < bufferTarget else { return }
        guard !isLoadingNewWords else { return }

        isLoadingNewWords = true
        defer { isLoadingNewWords = false }

        let batch: [String]
        do {
            batch = try await randomWordService.fetchRandomWordBatch(
                limit: max(24, learningSettings.newWordsPerDay * 3),
                allowedWordLevels: allowedDifficultyLevels
            )
        } catch {
            batch = fallbackLessonWords.shuffled()
        }

        let existing = Set(lessonWords)
        let filtered = batch.filter { word in
            let normalized = normalizedWordID(for: word)
            return !normalized.isEmpty
                && !completedWordIDs.contains(normalized)
                && !completedCurrentWordIDs.contains(normalized)
                && !existing.contains(word)
        }

        if filtered.isEmpty, lessonWords.isEmpty {
            let fallback = fallbackLessonWords.filter { word in
                let normalized = normalizedWordID(for: word)
                return !completedWordIDs.contains(normalized) && !completedCurrentWordIDs.contains(normalized)
            }

            if fallback.isEmpty {
                completedCurrentWordIDs.removeAll()
                lessonWords.append(contentsOf: fallbackLessonWords.shuffled().prefix(12))
            } else {
                lessonWords.append(contentsOf: fallback.shuffled().prefix(12))
            }
        } else {
            lessonWords.append(contentsOf: filtered)
        }
    }

    private func loadVocabularyProgress() {
        completedWordIDs = loadStringSet(forKey: StorageKeys.completedVocabularyWords)
        reviewWords = loadReviewWords()
    }

    private func loadReviewWords() -> [Word] {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.reviewVocabularyWords),
              let words = try? JSONDecoder().decode([Word].self, from: data) else {
            return []
        }
        return words
    }

    private func persistCompletedWordIDs() {
        let words = Array(completedWordIDs).sorted()
        UserDefaults.standard.set(words, forKey: StorageKeys.completedVocabularyWords)
    }

    private func persistReviewWords() {
        guard let encoded = try? JSONEncoder().encode(reviewWords) else { return }
        UserDefaults.standard.set(encoded, forKey: StorageKeys.reviewVocabularyWords)
    }

    private func loadStringSet(forKey key: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    private func normalizedWordID(for value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func reviewCard(for word: Word) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text(word.word.capitalizedIfAvailable)
                    .font(EngifyTypography.bodyStrong)
                    .foregroundStyle(EngifyColors.textPrimary)

                VocabularyBadge(text: displayValue(word.partOfSpeech.capitalizedIfAvailable), tint: theme.accentColor)
                Spacer(minLength: 0)
            }

            if !word.pronunciation.isEmpty {
                Text(word.pronunciation)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(EngifyColors.textSecondary)
            }

            Text(displayValue(word.meaning))
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textPrimary)

            if #available(iOS 16.0, *) {
                Text(word.example)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(EngifyColors.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Fallback on earlier versions
            }

            Button {
                startReview(word)
            } label: {
                Label("Review This Word", systemImage: "arrow.up.left.circle.fill")
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.accentColor.opacity(0.08))
        )
    }

    private func displayValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "N/A" : value
    }

    private func preferredMeaning(for entry: DictionaryEntry) -> String {
        let translated = displayValue(entry.vietnameseMeaning)
        if translated != "N/A" {
            return translated
        }
        return displayValue(entry.definition)
    }

    private var allowedDifficultyLevels: Set<String>? {
        guard learningSettings.difficultyLock else { return nil }

        switch surveyManager.cachedResponse?.englishLevel {
        case "advanced":
            return ["A1", "A2", "B1", "B2", "C1"]
        case "intermediate":
            return ["A1", "A2", "B1", "B2"]
        case "beginner", .none:
            return ["A1", "A2"]
        default:
            return ["A1", "A2"]
        }
    }

    private var difficultyLockSummary: String {
        guard let allowedDifficultyLevels else {
            return "Difficulty lock is off."
        }

        return "Difficulty lock is on. Engify prefers \(allowedDifficultyLevels.sorted().joined(separator: ", ")) words when level data is available."
    }

    private func tutorNote(for entry: DictionaryEntry) -> String {
        let word = displayValue(entry.word)
        let partOfSpeech = displayValue(entry.partOfSpeech).lowercased()
        let meaning = preferredMeaning(for: entry)

        switch learningSettings.explanationDepth {
        case "detailed":
            if partOfSpeech.contains("verb") {
                return "\"\(word)\" is an action word. Build one sentence with who does it and one sentence with when it happens."
            } else if partOfSpeech.contains("adjective") {
                return "\"\(word)\" describes something. Pair it with a familiar noun so the meaning feels easier to remember."
            }
            return "\"\(word)\" means \(meaning). Use it once in a personal sentence and once in an everyday situation."
        case "balanced":
            return "\"\(word)\" means \(meaning). Try saying it once in your own sentence."
        default:
            return meaning
        }
    }

    private func extraExamples(for entry: DictionaryEntry) -> [String] {
        let word = displayValue(entry.word)
        let partOfSpeech = displayValue(entry.partOfSpeech).lowercased()

        if partOfSpeech.contains("verb") {
            return [
                "I want to \(word) this idea more clearly.",
                "We can \(word) the new word again tomorrow."
            ]
        }

        if partOfSpeech.contains("adjective") {
            return [
                "The lesson felt more \(word) after one review.",
                "A \(word) example can make difficult vocabulary easier."
            ]
        }

        return [
            "\"\(word)\" appeared in today's study session.",
            "I added \(word) to my review list for later."
        ]
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

    private func initializeVocabularyExperience() async {
        loadVocabularyProgress()
        if !reviewWords.isEmpty {
            reviewMode = .showing
        }
        await refillLessonWordsIfNeeded(force: true)
        await searchLessonWord()
        await refillLessonWordsIfNeeded()
    }

    private func startReview(_ word: Word) {
        lessonWords.removeAll { normalizedWordID(for: $0) == normalizedWordID(for: word.word) }
        lessonWords.insert(normalizedWordID(for: word.word), at: 0)

        Task {
            await searchLessonWord()
        }
    }

    private func playAudioForCurrentWord() {
        guard let url = currentEntry.audioURL else { return }

        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()

        guard learningSettings.repeatPronunciation else { return }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard audioPlayer != nil else { return }
            await audioPlayer?.seek(to: .zero)
            audioPlayer?.play()
        }
    }
}
