import SwiftUI

struct PracticeView: View {
    @State private var activePracticeSheet: PracticeRoute?
    @State private var selectedGrammarTopic = 0
    @State private var speakingHintVisible = false
    @State private var selectedImageLessonIndex = 0
    @State private var imageLessonNotes = ""
    @State private var imageLessonSearchText = ""
    @State private var selectedDialogueScenarioIndex = 0
    @State private var dialogueResponseDraft = ""
    @State private var quizAnswers: [UUID: Int] = [:]
    @State private var showQuizResult = false
    @State private var currentQuizQuestions: [QuizQuestion] = []
    @State private var currentPracticeSessionID = UUID()
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @State private var showSettingsSheet = false
    @State private var showImageAPISettingsSheet = false

    var body: some View {
        EngifyScreenScroll {
            globalHeader
            routedContent
        }
        .engifySettingsSheet(isPresented: $showSettingsSheet)
        .engifySettingsSheet(isPresented: $showImageAPISettingsSheet, initialSection: .imageProviders)
        .sheet(item: $activePracticeSheet) { route in
            if #available(iOS 16.0, *) {
                NavigationView {
                    practiceSheetView(for: route)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            } else {
                // Fallback on earlier versions
            }
        }
        .onChange(of: authManager.isGuestMode) { isGuestMode in
            if isGuestMode {
                activePracticeSheet = nil
            }
        }
    }

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: PracticeRoute.dashboard.headerTitle,
            subtitle: PracticeRoute.dashboard.headerSubtitle,
            showSettings: $showSettingsSheet
        )
    }

    private var routedContent: some View {
        Group {
            if authManager.isGuestMode {
                lockedPracticeExperience
            } else {
                PracticeDashboardSelectorGrid(accentColor: theme.accentColor) { selectedRoute in
                    present(route: selectedRoute)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var lockedPracticeExperience: some View {
        ZStack {
            PracticeDashboardSelectorGrid(
                accentColor: theme.accentColor,
                onSelect: { _ in }
            )
            .blur(radius: 7)
            .allowsHitTesting(false)

            EngifyCard(tint: theme.accentColor) {
                VStack(spacing: Spacing.lg) {
                    EngifyIconBadge(systemImage: "lock.fill", tint: theme.accentColor, size: 64)

                    VStack(spacing: Spacing.sm) {
                        Text("Practice Is Locked in Guest Mode")
                            .font(EngifyTypography.sectionTitle)
                            .foregroundStyle(EngifyColors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Sign in to unlock the Speaking Hub, Grammar Academy, and Quick Quiz Arena while saving every streak and score.")
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    SecondaryButton(
                        title: "Unlock Practice",
                        systemImage: "lock.open.fill",
                        action: {
                            authManager.presentAccountRequired(for: .practice)
                        },
                        feedbackEvent: .errorBuzz
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }
            .padding(.top, 72)
        }
    }

    @ViewBuilder
    private func practiceSheetView(for route: PracticeRoute) -> some View {
        EngifyScreenScroll(bottomInset: 40) {
            switch route {
            case .dashboard:
                EmptyView()

            case .speaking:
                DedicatedSpeakingPracticeView(
                    accentColor: theme.accentColor,
                    speakingSentence: EngifySampleData.speakingSentence,
                    speakingHintVisible: $speakingHintVisible,
                    learningSettings: learningSettings
                )

            case .grammar:
                DedicatedGrammarLessonView(
                    accentColor: theme.accentColor,
                    grammarTopics: EngifySampleData.grammarTopics,
                    selectedTopicIndex: $selectedGrammarTopic,
                    learningSettings: learningSettings
                )

            case .image:
                DedicatedImagePracticeView(
                    accentColor: theme.accentColor,
                    lessons: EngifySampleData.practiceImageLessons,
                    selectedLessonIndex: $selectedImageLessonIndex,
                    learnerNotes: $imageLessonNotes,
                    searchText: $imageLessonSearchText,
                    learningSettings: learningSettings,
                    onComplete: completeImageLesson,
                    onOpenAPISettings: { showImageAPISettingsSheet = true }
                )

            case .dialogue:
                DedicatedDialoguePracticeView(
                    accentColor: theme.accentColor,
                    scenarios: EngifySampleData.practiceDialogueScenarios,
                    selectedScenarioIndex: $selectedDialogueScenarioIndex,
                    responseDraft: $dialogueResponseDraft,
                    learningSettings: learningSettings,
                    onComplete: completeDialogueLesson
                )

            case .quiz:
                DedicatedQuizView(
                    accentColor: theme.accentColor,
                    theme: theme,
                    learningSettings: learningSettings,
                    questions: currentQuizQuestions,
                    quizAnswers: $quizAnswers,
                    showQuizResult: $showQuizResult,
                    quizScore: quizScore,
                    scoreColor: scoreColor,
                    onSelectAnswer: selectAnswer,
                    onCheckScore: checkQuizScore,
                    onRefresh: refreshQuiz,
                    onAppear: refreshQuiz
                )
            }
        }
        .overlay {
            LessonCompleteOverlay()
        }
        .overlay {
            LevelUpOverlay()
        }
        .overlay {
            BadgeUnlockedOverlay()
        }
        .overlay(alignment: .bottom) {
            if gamification.showXPGain {
                XPGainToast(amount: gamification.lastXPGained)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scoreColor: Color {
        let percentage = Double(quizScore) / Double(max(1, currentQuizQuestions.count))
        if percentage >= 1 {
            return EngifyColors.sage
        } else if percentage >= 0.6 {
            return theme.accentColor
        } else {
            return EngifyColors.coral
        }
    }

    private var quizScore: Int {
        currentQuizQuestions.reduce(into: 0) { result, question in
            if quizAnswers[question.id] == question.answerIndex {
                result += 1
            }
        }
    }

    private func present(route: PracticeRoute) {
        guard route != .dashboard else { return }
        activePracticeSheet = route
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func selectAnswer(for question: QuizQuestion, selected index: Int) {
        guard !showQuizResult else { return }

        let previousSelection = quizAnswers[question.id]
        quizAnswers[question.id] = index

        if previousSelection == nil, index != question.answerIndex {
            gamification.loseHeart()
        }
    }

    private func checkQuizScore() {
        guard !showQuizResult else { return }

        showQuizResult = true
        let earnedXP = quizScore * 5

        if quizScore == currentQuizQuestions.count, !currentQuizQuestions.isEmpty {
            gamification.completeLesson(type: .practice, xpEarned: earnedXP)
            _ = gamification.awardPoints(for: .perfectPractice(sessionID: currentPracticeSessionID))
        } else if earnedXP > 0 {
            gamification.earnXP(earnedXP)
        }
    }

    private func refreshQuiz() {
        currentPracticeSessionID = UUID()
        currentQuizQuestions = randomizedQuizQuestions()
        quizAnswers.removeAll()
        showQuizResult = false
    }

    private func completeImageLesson() {
        gamification.completeLesson(type: .practice, xpEarned: 12)
    }

    private func completeDialogueLesson() {
        gamification.completeLesson(type: .practice, xpEarned: 15)
    }

    private func randomizedQuizQuestions() -> [QuizQuestion] {
        let questionCount = min(5, EngifySampleData.practiceQuizQuestions.count)

        return EngifySampleData.practiceQuizQuestions
            .shuffled()
            .prefix(questionCount)
            .map(randomizeQuestionOptions)
    }

    private func randomizeQuestionOptions(for question: QuizQuestion) -> QuizQuestion {
        let answer = question.options[question.answerIndex]
        let shuffledOptions = question.options.shuffled()
        let shuffledAnswerIndex = shuffledOptions.firstIndex(of: answer) ?? question.answerIndex

        return QuizQuestion(
            prompt: question.prompt,
            options: shuffledOptions,
            answerIndex: shuffledAnswerIndex,
            explanation: question.explanation
        )
    }
}

private enum PracticeRoute: Int, Hashable, Identifiable {
    case dashboard
    case speaking
    case grammar
    case image
    case dialogue
    case quiz

    var id: Int { rawValue }

    var headerTitle: String {
        switch self {
        case .dashboard:
            return "Practice"
        case .speaking:
            return "Speaking Hub"
        case .grammar:
            return "Grammar Academy"
        case .image:
            return "Scene Studio"
        case .dialogue:
            return "Dialogue Lab"
        case .quiz:
            return "Quick Quiz Arena"
        }
    }

    var headerSubtitle: String {
        switch self {
        case .dashboard:
            return "Choose your next focused workout"
        case .speaking:
            return "Train your pronunciation and verbal fluency"
        case .grammar:
            return "Master structures, tenses, and sentence building"
        case .image:
            return "Study scenes, build vocabulary, and describe what you notice"
        case .dialogue:
            return "Practice useful real-life conversations with guided support"
        case .quiz:
            return "Test your skills with rapid-fire reps"
        }
    }
}

private struct PracticeDashboardSelectorGrid: View {
    let accentColor: Color
    let onSelect: (PracticeRoute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            PracticeHubCard(
                accentColor: accentColor,
                eyebrow: "Section A • Speaking Hub",
                title: "Speaking Practice",
                subtitle: "Train your pronunciation and verbal fluency.",
                systemImage: "mic.fill",
                route: .speaking,
                layout: .wide,
                onSelect: onSelect
            )

            HStack(alignment: .top, spacing: Spacing.md) {
                PracticeHubCard(
                    accentColor: accentColor,
                    eyebrow: "Section B • Grammar Academy",
                    title: "Grammar Lessons",
                    subtitle: "Master structures, tenses, and sentence building.",
                    systemImage: "book.closed.fill",
                    route: .grammar,
                    layout: .compact,
                    onSelect: onSelect
                )

                PracticeHubCard(
                    accentColor: accentColor,
                    eyebrow: "Section C • Quick Quiz Arena",
                    title: "Interactive Quizzes",
                    subtitle: "Test your skills with rapid-fire reps.",
                    systemImage: "checklist.checked",
                    route: .quiz,
                    layout: .compact,
                    onSelect: onSelect
                )
            }

            HStack(alignment: .top, spacing: Spacing.md) {
                PracticeHubCard(
                    accentColor: accentColor,
                    eyebrow: "Section D • Scene Studio",
                    title: "Image Lessons",
                    subtitle: "Describe visual scenes and learn practical vocabulary.",
                    systemImage: "photo.fill.on.rectangle.fill",
                    route: .image,
                    layout: .compact,
                    onSelect: onSelect
                )

                PracticeHubCard(
                    accentColor: accentColor,
                    eyebrow: "Section E • Dialogue Lab",
                    title: "Roleplay Dialogues",
                    subtitle: "Practice common conversations with sentence support.",
                    systemImage: "message.fill",
                    route: .dialogue,
                    layout: .compact,
                    onSelect: onSelect
                )
            }
        }
    }
}

private struct PracticeHubCard: View {
    enum Layout {
        case wide
        case compact
    }

    let accentColor: Color
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let route: PracticeRoute
    let layout: Layout
    let onSelect: (PracticeRoute) -> Void

    var body: some View {
        Button {
            withAnimation(EngifySpring.jellyRelease) {
                onSelect(route)
            }
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.20),
                                EngifyColors.surface.opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(accentColor.opacity(0.18), lineWidth: 1)
                    )

                Image(systemName: systemImage)
                    .font(.system(size: layout == .wide ? 74 : 58, weight: .black))
                    .foregroundStyle(accentColor.opacity(0.14))
                    .offset(
                        x: layout == .wide ? 150 : 20,
                        y: layout == .wide ? 10 : 26
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(eyebrow)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .textCase(.uppercase)

                    Text(title)
                        .font(layout == .wide ? EngifyTypography.screenTitle : EngifyTypography.sectionTitle)
                        .foregroundStyle(EngifyColors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.sm) {
                        Text("Open")
                            .font(EngifyTypography.caption.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.top, layout == .wide ? Spacing.sm : 0)
                }
                .padding(layout == .wide ? Spacing.xl : Spacing.lg)
                .frame(maxWidth: .infinity, minHeight: layout == .wide ? 210 : 240, alignment: .topLeading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }
}

private struct PracticeDetailHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(EngifyTypography.screenTitle)
                .foregroundStyle(EngifyColors.textPrimary)

            Text(subtitle)
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DedicatedSpeakingPracticeView: View {
    let accentColor: Color
    let speakingSentence: String
    @Binding var speakingHintVisible: Bool
    let learningSettings: LearningSettingsManager
    @State private var typedTranscript = ""
    @State private var hasReviewedRep = false

    private var pronunciationModelLabel: String {
        switch learningSettings.pronunciationModel {
        case "uk_english":
            return "UK English"
        case "australian":
            return "Australian English"
        default:
            return "US English"
        }
    }

    private var speakingSpeedLabel: String {
        learningSettings.speakingSpeed.capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            PracticeDetailHeader(
                title: "Speaking Practice",
                subtitle: "Focus on one target phrase at a time and build calm, repeatable fluency."
            )

            EngifyCard(tint: accentColor) {
                VStack(alignment: .center, spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Target phrase")
                            .font(EngifyTypography.caption.weight(.semibold))
                            .foregroundStyle(accentColor)
                            .textCase(.uppercase)

                        Text(speakingSentence)
                            .font(.system(size: 24, weight: .regular, design: .rounded))
                            .foregroundStyle(EngifyColors.textPrimary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: 0)

                    Button {
                        withAnimation(EngifySpring.jellyRelease) {
                            speakingHintVisible.toggle()
                        }
                    } label: {
                        VStack(spacing: Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [accentColor.opacity(0.82), accentColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 150, height: 150)
                                    .shadow(color: accentColor.opacity(0.28), radius: 18, x: 0, y: 14)

                                Image(systemName: "mic.fill")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(EngifyColors.textInverse)
                            }

                            Text("Start Speaking")
                                .font(EngifyTypography.sectionTitle)
                                .foregroundStyle(EngifyColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .engifyJellyPress()

                    Spacer(minLength: 0)

                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            VocabularyBadge(text: "\(speakingSpeedLabel) pace", tint: accentColor)
                            VocabularyBadge(text: pronunciationModelLabel, tint: accentColor)
                            if learningSettings.speechFeedbackEnabled {
                                VocabularyBadge(text: "Feedback on", tint: accentColor)
                            }
                        }

                        if learningSettings.transcriptVisible {
                            Text("Transcript preview is enabled for speaking reviews.")
                                .font(EngifyTypography.caption)
                                .foregroundStyle(EngifyColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Group {
                        if speakingHintVisible {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(accentColor)

                                    Text(speakingHintText)
                                        .font(EngifyTypography.caption)
                                        .foregroundStyle(EngifyColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if learningSettings.microphoneEnabled && learningSettings.microphonePermissionStatus == .granted {
                                    VStack(alignment: .leading, spacing: Spacing.sm) {
                                        Text("Type what you said")
                                            .font(EngifyTypography.caption.weight(.semibold))
                                            .foregroundStyle(EngifyColors.textPrimary)

                                        TextField("Type your spoken phrase for self-check", text: $typedTranscript)
                                            .textInputAutocapitalization(.sentences)
                                            .autocorrectionDisabled()
                                            .font(EngifyTypography.body)
                                            .padding(.horizontal, Spacing.md)
                                            .frame(minHeight: 52)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(EngifyColors.surface)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
                                            )

                                        Button {
                                            hasReviewedRep = true
                                        } label: {
                                            Text("Review My Rep")
                                                .font(EngifyTypography.caption.weight(.semibold))
                                                .foregroundStyle(EngifyColors.textInverse)
                                                .padding(.horizontal, Spacing.md)
                                                .padding(.vertical, Spacing.sm)
                                                .background(accentColor)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(typedTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                        if hasReviewedRep {
                                            speakingReviewCard
                                        }
                                    }
                                }
                            }
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(accentColor.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            Text("Tap the microphone when you're ready for a focused speaking rep.")
                                .font(EngifyTypography.caption)
                                .foregroundStyle(EngifyColors.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 460)
            }
        }
    }

    private var speakingHintText: String {
        if !learningSettings.microphoneEnabled || learningSettings.microphonePermissionStatus != .granted {
            return "Enable microphone access in Settings to start speaking practice here."
        }

        if learningSettings.speechFeedbackEnabled {
            if learningSettings.transcriptVisible {
                return "Speak the phrase out loud, then type what you said so Engify can review it with transcript-based feedback."
            }
            return "Speak the phrase out loud, then type what you said so Engify can review the accuracy without showing the transcript."
        }

        return "Microphone practice is on. Speak the phrase out loud, then type what you said for a simple self-check."
    }

    private var normalizedTargetWords: [String] {
        normalizedWords(from: speakingSentence)
    }

    private var normalizedTranscriptWords: [String] {
        normalizedWords(from: typedTranscript)
    }

    private var matchedWordsCount: Int {
        normalizedTranscriptWords.reduce(into: 0) { result, word in
            if normalizedTargetWords.contains(word) {
                result += 1
            }
        }
    }

    private var missingWords: [String] {
        normalizedTargetWords.filter { !normalizedTranscriptWords.contains($0) }
    }

    private var extraWords: [String] {
        normalizedTranscriptWords.filter { !normalizedTargetWords.contains($0) }
    }

    private var selfCheckScore: Int {
        let total = max(1, normalizedTargetWords.count)
        return Int((Double(matchedWordsCount) / Double(total)) * 100)
    }

    private var speakingReviewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if learningSettings.speechFeedbackEnabled {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(feedbackTitle)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text("Self-check score: \(selfCheckScore)%")
                        .font(EngifyTypography.caption.weight(.semibold))
                        .foregroundStyle(scoreTint)
                }
            }

            if learningSettings.transcriptVisible {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Transcript")
                        .font(EngifyTypography.caption.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(typedTranscript.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(feedbackMessage)
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if learningSettings.explanationDepth == "detailed" {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if !missingWords.isEmpty {
                        Text("Missing words: \(missingWords.joined(separator: ", "))")
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                    }

                    if !extraWords.isEmpty {
                        Text("Extra words: \(extraWords.joined(separator: ", "))")
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EngifyColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var feedbackTitle: String {
        switch learningSettings.correctionStyle {
        case "strict":
            return selfCheckScore >= 85 ? "Strong rep" : "Needs a cleaner repeat"
        case "gentle":
            return selfCheckScore >= 85 ? "Nice progress" : "Good try, refine one more time"
        default:
            return selfCheckScore >= 85 ? "Solid speaking rep" : "Try one more focused rep"
        }
    }

    private var feedbackMessage: String {
        switch learningSettings.correctionStyle {
        case "strict":
            return learningSettings.explanationDepth == "simple"
                ? "Match the target phrase more closely."
                : "Focus on accuracy. Repeat the target phrase and close the gap on any missing words."
        case "gentle":
            return learningSettings.explanationDepth == "simple"
                ? "You are close. Try once more."
                : "You are building good speaking habits. Repeat the phrase once more and smooth out the missing parts."
        default:
            return learningSettings.explanationDepth == "simple"
                ? "Try another rep to improve the match."
                : "Repeat the phrase once more and listen for rhythm, word order, and any words you skipped."
        }
    }

    private var scoreTint: Color {
        if selfCheckScore >= 85 {
            return accentColor
        } else if selfCheckScore >= 60 {
            return accentColor
        }
        return EngifyColors.coral
    }

    private func normalizedWords(from text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}

private struct DedicatedGrammarLessonView: View {
    let accentColor: Color
    let grammarTopics: [(title: String, explanation: String, examples: [String])]
    @Binding var selectedTopicIndex: Int
    let learningSettings: LearningSettingsManager

    private var topic: (title: String, explanation: String, examples: [String]) {
        grammarTopics[selectedTopicIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            PracticeDetailHeader(
                title: "Grammar Lessons",
                subtitle: "Browse a topic, settle into the rule, and give examples enough room to actually teach."
            )

            EngifyCard(tint: accentColor) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Lesson selector")
                                .font(EngifyTypography.caption.weight(.semibold))
                                .foregroundStyle(accentColor)
                                .textCase(.uppercase)

                            Text("Lesson \(selectedTopicIndex + 1) of \(grammarTopics.count)")
                                .font(EngifyTypography.body)
                                .foregroundStyle(EngifyColors.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Menu {
                            ForEach(grammarTopics.indices, id: \.self) { index in
                                Button(grammarTopics[index].title) {
                                    updateTopicSelection(to: index)
                                }
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text(topic.title)
                                    .font(EngifyTypography.bodyStrong)
                                    .foregroundStyle(EngifyColors.textPrimary)
                                    .lineLimit(1)

                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(accentColor)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(accentColor.opacity(0.10))
                            .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: Spacing.md) {
                        SecondaryButton(
                            title: "Previous",
                            systemImage: "arrow.left",
                            action: selectPreviousTopic,
                            size: .large
                        )

                        SecondaryButton(
                            title: "Next",
                            systemImage: "arrow.right",
                            action: selectNextTopic,
                            size: .large
                        )
                    }
                }
            }

            EngifyCard {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(topic.title)
                            .font(EngifyTypography.screenTitle)
                            .foregroundStyle(EngifyColors.textPrimary)

                        Text(tutorAdjustedExplanation)
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Sentence blueprints")
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        ForEach(topic.examples, id: \.self) { example in
                            HStack(alignment: .top, spacing: Spacing.md) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(accentColor)

                                Text(example)
                                    .font(EngifyTypography.body)
                                    .foregroundStyle(EngifyColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    if learningSettings.generateExtraExamples {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("More examples")
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

                            ForEach(extraGrammarExamples, id: \.self) { example in
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(accentColor)

                                    Text(example)
                                        .font(EngifyTypography.body)
                                        .foregroundStyle(EngifyColors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Translation keys")
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        ForEach(grammarTranslationKeys(for: topic.title), id: \.self) { key in
                            Text(key)
                                .font(EngifyTypography.body)
                                .foregroundStyle(EngifyColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
            }
        }
    }

    private var tutorAdjustedExplanation: String {
        switch learningSettings.explanationDepth {
        case "detailed":
            return topic.explanation + " Focus on one signal pattern, then build two new sentences with different subjects or time markers."
        case "balanced":
            return topic.explanation + " Try one short personal example after reading the rule."
        default:
            return topic.explanation
        }
    }

    private var extraGrammarExamples: [String] {
        switch topic.title {
        case "Present Simple":
            return [
                "My brother practices English before class.",
                "We usually review new words after dinner."
            ]
        case "There is / There are":
            return [
                "There is a notebook beside my laptop.",
                "There are three useful phrases on the board."
            ]
        case "Past Simple":
            return [
                "I watched a short English video last night.",
                "She finished her homework before bed."
            ]
        default:
            return [
                "Write one sentence about your routine using this pattern.",
                "Say the sentence aloud once, then change the subject and repeat it."
            ]
        }
    }

    private func grammarTranslationKeys(for title: String) -> [String] {
        switch title {
        case "Present Simple":
            return [
                "habits = thoi quen",
                "every day / usually / often = moi ngay / thuong / hay",
                "he, she, it + verb-s = can ghi nho duoi -s"
            ]
        case "There is / There are":
            return [
                "there is = co (so it)",
                "there are = co (so nhieu)",
                "on the table / in the room = tren ban / trong phong"
            ]
        case "Past Simple":
            return [
                "yesterday / last night = hom qua / toi qua",
                "verb-ed or irregular form = dong tu qua khu",
                "finished action = hanh dong da hoan thanh"
            ]
        default:
            return [
                "main idea = y chinh cua cau truc",
                "signal words = tu khoa nhan biet",
                "build one sentence, then vary it = lap 1 cau mau roi bien doi"
            ]
        }
    }

    private func updateTopicSelection(to index: Int) {
        guard grammarTopics.indices.contains(index) else { return }

        withAnimation(EngifySpring.tabSlide) {
            selectedTopicIndex = index
        }
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func selectPreviousTopic() {
        let previousIndex = selectedTopicIndex == 0 ? grammarTopics.count - 1 : selectedTopicIndex - 1
        updateTopicSelection(to: previousIndex)
    }

    private func selectNextTopic() {
        let nextIndex = selectedTopicIndex == grammarTopics.count - 1 ? 0 : selectedTopicIndex + 1
        updateTopicSelection(to: nextIndex)
    }
}

private struct DedicatedImagePracticeView: View {
    let accentColor: Color
    let lessons: [PracticeImageLesson]
    @Binding var selectedLessonIndex: Int
    @Binding var learnerNotes: String
    @Binding var searchText: String
    let learningSettings: LearningSettingsManager
    let onComplete: () -> Void
    let onOpenAPISettings: () -> Void
    @State private var submittedSearchText = ""
    @State private var webLessons: [PracticeImageLesson] = []
    @State private var isSearchingWeb = false
    @State private var imageSearchStatusMessage: String?
    @State private var imageSearchAttempted = false
    @State private var activeSearchRequestID = UUID()

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var normalizedSubmittedSearchText: String {
        submittedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var hasSubmittedSearch: Bool {
        !normalizedSubmittedSearchText.isEmpty
    }

    private var activeSearchText: String {
        normalizedSubmittedSearchText
    }

    private var searchKeywords: [String] {
        activeSearchText
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count > 1 }
    }

    private var activeLessons: [PracticeImageLesson] {
        if hasSubmittedSearch {
            if !webLessons.isEmpty {
                return webLessons
            }

            return filteredLessons
        }

        return lessons
    }

    private var filteredLessons: [PracticeImageLesson] {
        guard hasSubmittedSearch else { return lessons }

        return lessons
            .map { lesson in
                (lesson, score(for: lesson))
            }
            .filter { $0.1 > 0 }
            .sorted {
                if $0.1 == $1.1 {
                    return $0.0.title < $1.0.title
                }
                return $0.1 > $1.1
            }
            .map(\.0)
    }

    private var displayedLesson: PracticeImageLesson? {
        if activeLessons.indices.contains(selectedLessonIndex) {
            return activeLessons[selectedLessonIndex]
        }

        return activeLessons.first
    }

    private var pexelsSearchURL: URL? {
        let topic = normalizedSearchText.isEmpty ? "flowers" : normalizedSearchText
        let slug = topic
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .joined(separator: "-")

        return URL(string: "https://www.pexels.com/search/\(slug)/")
    }

    private var tutorBotKeywords: [String] {
        let topicTokens = searchKeywords
        let matchedTopics = activeLessons
            .flatMap(\.searchTopics)
            .filter { topic in
                topicTokens.isEmpty || topicTokens.contains(where: { topic.localizedCaseInsensitiveContains($0) })
            }

        return Array(Set(topicTokens + matchedTopics.map { $0.lowercased() }))
            .sorted()
    }

    private var tutorBotVocabulary: [String] {
        let prioritizedWords = activeLessons
            .prefix(3)
            .flatMap(\.focusVocabulary)
            .filter { word in
                tutorBotKeywords.isEmpty || tutorBotKeywords.contains(where: { word.localizedCaseInsensitiveContains($0) })
            }

        let fallbackWords = activeLessons
            .prefix(3)
            .flatMap(\.focusVocabulary)

        return Array(Set((prioritizedWords.isEmpty ? fallbackWords : prioritizedWords).map { $0.lowercased() }))
            .sorted()
            .map { $0.capitalized }
    }

    private var tutorBotSummary: String {
        if normalizedSearchText.isEmpty {
            return "Type any topic and press Search on the keyboard to load a carousel of matching image lessons."
        }

        if !hasSubmittedSearch {
            return "Press Search on the keyboard to show image results for '\(searchText)'."
        }

        if isSearchingWeb {
            return "Searching the web for image lessons about '\(submittedSearchText)'."
        }

        if !webLessons.isEmpty {
            return "Engify loaded \(webLessons.count) web image \(webLessons.count == 1 ? "result" : "results") for '\(submittedSearchText)'."
        }

        if filteredLessons.isEmpty {
            return "No image cards match yet. Try a broader topic like flowers, nature, beach, business, food, or travel."
        }

        let keywordPreview = tutorBotKeywords.prefix(5).joined(separator: ", ")
        return "Web results are unavailable right now, so Engify tutor filtered \(filteredLessons.count) backup image \(filteredLessons.count == 1 ? "result" : "results") for '\(submittedSearchText)' and found topic words like \(keywordPreview.isEmpty ? "scene vocabulary" : keywordPreview)."
    }

    private var searchStatusColor: Color {
        if isSearchingWeb {
            return accentColor
        }

        if !webLessons.isEmpty {
            return EngifyColors.sage
        }

        if imageSearchAttempted, imageSearchStatusMessage != nil {
            return EngifyColors.coral
        }

        return EngifyColors.textSecondary
    }

    private var preferredConfiguredProviderName: String? {
        learningSettings.imageAPIProviders.first {
            $0.isEnabled && !$0.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }?.name
    }

    private var configuredProviderSummary: String {
        if let preferredConfiguredProviderName {
            return "Live image search is ready with \(preferredConfiguredProviderName)."
        }

        return "Add an image API key in Settings to unlock live web image lessons."
    }

    private var searchFieldAccessibilityHint: String {
        if let preferredConfiguredProviderName {
            return "Type a topic and press Search to load live image lessons from \(preferredConfiguredProviderName)."
        }

        return "Type a topic and press Search. Without an API key, Engify will show backup image lessons."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            PracticeDetailHeader(
                title: "Image Lessons",
                subtitle: "Use scene-based prompts to practice observation, vocabulary, and natural spoken description."
            )

            EngifyCard(tint: accentColor) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Search any topic")
                            .font(EngifyTypography.caption.weight(.semibold))
                            .foregroundStyle(accentColor)
                            .textCase(.uppercase)

                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(accentColor)

                            TextField("Type flowers, beach, office, food, or any topic", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(EngifyTypography.body)
                                .submitLabel(.search)
                                .onSubmit {
                                    applySearchSelection()
                                }
                                .accessibilityLabel("Search image lessons")
                                .accessibilityHint(searchFieldAccessibilityHint)

                            if !searchText.isEmpty {
                                Button {
                                    clearSearch()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(EngifyColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Clear image search")
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .frame(minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(EngifyColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSearchingWeb ? accentColor.opacity(0.42) : accentColor.opacity(0.14), lineWidth: isSearchingWeb ? 1.5 : 1)
                        )

                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: preferredConfiguredProviderName == nil ? "lock.open.trianglebadge.exclamationmark" : "bolt.badge.checkmark.fill")
                                .foregroundStyle(preferredConfiguredProviderName == nil ? EngifyColors.warning : EngifyColors.sage)
                                .font(.caption.weight(.semibold))

                            Text(configuredProviderSummary)
                                .font(EngifyTypography.caption)
                                .foregroundStyle(EngifyColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if preferredConfiguredProviderName == nil {
                            Button {
                                onOpenAPISettings()
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "key.fill")
                                        .font(.caption.weight(.bold))
                                    Text("Configure API Key")
                                        .font(EngifyTypography.bodyStrong)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                }
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(accentColor.opacity(0.10))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens Settings to configure an image provider API key.")
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(EngifySampleData.practiceImageTopics, id: \.self) { topic in
                                    Button {
                                        searchText = topic
                                        applySearchSelection()
                                    } label: {
                                        VocabularyBadge(text: topic.capitalized, tint: accentColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        Text(tutorBotSummary)
                            .font(EngifyTypography.caption)
                            .foregroundStyle(summaryColor)
                            .fixedSize(horizontal: false, vertical: true)

                        if let imageSearchStatusMessage, !imageSearchStatusMessage.isEmpty {
                            statusBanner(
                                text: imageSearchStatusMessage,
                                color: searchStatusColor,
                                systemImage: statusBannerIcon
                            )
                        }

                        if let pexelsSearchURL {
                            Link(destination: pexelsSearchURL) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Open Pexels Search")
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption.weight(.bold))
                                }
                                .font(EngifyTypography.bodyStrong)
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(accentColor.opacity(0.10))
                                .clipShape(Capsule())
                            }
                            .accessibilityHint("Opens the public Pexels website for the current topic.")
                        }
                    }

                    HStack(alignment: .top, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Image results")
                                .font(EngifyTypography.caption.weight(.semibold))
                                .foregroundStyle(accentColor)
                                .textCase(.uppercase)

                            Text(resultCountLabel)
                                .font(EngifyTypography.body)
                                .foregroundStyle(EngifyColors.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Menu {
                            ForEach(activeLessons.indices, id: \.self) { index in
                                Button(activeLessons[index].title) {
                                    updateSelection(to: index)
                                }
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text(displayedLesson?.title ?? "No matches")
                                    .font(EngifyTypography.bodyStrong)
                                    .foregroundStyle(EngifyColors.textPrimary)
                                    .lineLimit(1)

                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(accentColor)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(accentColor.opacity(0.10))
                            .clipShape(Capsule())
                        }
                        .disabled(activeLessons.isEmpty)
                    }

                    if !activeLessons.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.md) {
                                ForEach(Array(activeLessons.enumerated()), id: \.element.id) { index, lesson in
                                    Button {
                                        updateSelection(to: index)
                                    } label: {
                                        ImagePracticeResultCard(
                                            lesson: lesson,
                                            accentColor: accentColor,
                                            isSelected: displayedLesson?.id == lesson.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } else {
                        EngifyCard(tint: accentColor.opacity(0.35)) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("No image lessons found")
                                    .font(EngifyTypography.bodyStrong)
                                    .foregroundStyle(EngifyColors.textPrimary)

                                Text("Try another topic and press Search to refresh the carousel.")
                                    .font(EngifyTypography.body)
                                    .foregroundStyle(EngifyColors.textSecondary)
                            }
                        }
                    }

                    HStack(spacing: Spacing.md) {
                        SecondaryButton(
                            title: "Previous",
                            systemImage: "arrow.left",
                            action: selectPreviousLesson,
                            isDisabled: activeLessons.isEmpty,
                            size: .large
                        )

                        SecondaryButton(
                            title: "Next",
                            systemImage: "arrow.right",
                            action: selectNextLesson,
                            isDisabled: activeLessons.isEmpty,
                            size: .large
                        )
                    }
                }
            }

            EngifyCard {
                if let displayedLesson {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        ZStack(alignment: .topLeading) {
                            PracticeLessonImageView(
                                lesson: displayedLesson,
                                accentColor: accentColor,
                                cornerRadius: 28
                            )
                            .frame(minHeight: 250)
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.04),
                                        Color.black.opacity(0.50)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(accentColor.opacity(0.20), lineWidth: 1)
                            )

                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack(alignment: .center, spacing: Spacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 74, height: 74)

                                        Image(systemName: displayedLesson.systemImage)
                                            .font(.system(size: 30, weight: .bold))
                                            .foregroundStyle(.white)
                                    }

                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text(displayedLesson.locationLabel)
                                            .font(EngifyTypography.caption.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.90))
                                            .textCase(.uppercase)

                                        Text(displayedLesson.title)
                                            .font(EngifyTypography.screenTitle)
                                            .foregroundStyle(.white)
                                    }
                                }

                                Text(displayedLesson.sceneDescription)
                                    .font(EngifyTypography.body)
                                    .foregroundStyle(.white.opacity(0.90))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(Spacing.xl)
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Engify tutor bot")
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

                            EngifyCard(tint: accentColor) {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    HStack(alignment: .center, spacing: Spacing.sm) {
                                        Image(systemName: "brain.head.profile")
                                            .foregroundStyle(accentColor)

                                        Text("Filtered topic words")
                                            .font(EngifyTypography.bodyStrong)
                                            .foregroundStyle(EngifyColors.textPrimary)
                                    }

                                    FlexibleBadgeRow(
                                        items: tutorBotKeywords.isEmpty ? displayedLesson.searchTopics.map { $0.capitalized } : tutorBotKeywords.map { $0.capitalized },
                                        tint: accentColor
                                    )

                                    Text("Recommended vocabulary")
                                        .font(EngifyTypography.caption.weight(.semibold))
                                        .foregroundStyle(EngifyColors.textSecondary)

                                    FlexibleBadgeRow(
                                        items: tutorBotVocabulary.isEmpty ? displayedLesson.focusVocabulary : tutorBotVocabulary,
                                        tint: accentColor
                                    )

                                    Text("Style cue: \(displayedLesson.visualStyle)")
                                        .font(EngifyTypography.caption)
                                        .foregroundStyle(EngifyColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if displayedLesson.providerName != nil {
                                        ImageLessonAttributionView(lesson: displayedLesson, accentColor: accentColor)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Focus vocabulary")
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

                            FlexibleBadgeRow(items: displayedLesson.focusVocabulary, tint: accentColor)
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Guided prompts")
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

                            ForEach(Array(displayedLesson.guidedPrompts.enumerated()), id: \.offset) { index, prompt in
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    Text("\(index + 1)")
                                        .font(EngifyTypography.caption.weight(.bold))
                                        .foregroundStyle(accentColor)
                                        .frame(width: 18, alignment: .leading)

                                    Text(prompt)
                                        .font(EngifyTypography.body)
                                        .foregroundStyle(EngifyColors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Your response notes")
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

                            if #available(iOS 16.0, *) {
                                TextEditor(text: $learnerNotes)
                                    .scrollContentBackground(.hidden)
                                    .font(EngifyTypography.body)
                                    .frame(minHeight: 140)
                                    .padding(Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(accentColor.opacity(0.08))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(accentColor.opacity(0.16), lineWidth: 1)
                                    )
                            } else {
                                // Fallback on earlier versions
                            }

                            Text(displayedLesson.challengePrompt)
                                .font(EngifyTypography.caption)
                                .foregroundStyle(EngifyColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        PrimaryButton(
                            title: "Mark Image Lesson Complete",
                            systemImage: "sparkles",
                            action: onComplete,
                            feedbackEvent: .successPop
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("No lesson selected")
                            .font(EngifyTypography.sectionTitle)
                            .foregroundStyle(EngifyColors.textPrimary)

                        Text("Submit another topic to load a fresh set of image lesson cards.")
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)

                        SecondaryButton(
                            title: "Clear Search",
                            systemImage: "arrow.counterclockwise",
                            action: clearSearch,
                            fillsWidth: false,
                            tint: accentColor
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear {
            hydrateSubmittedSearchIfNeeded()
        }
    }

    private func updateSelection(to index: Int) {
        guard activeLessons.indices.contains(index) else { return }

        withAnimation(EngifySpring.tabSlide) {
            selectedLessonIndex = index
            learnerNotes = ""
        }
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func applySearchSelection() {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        withAnimation(EngifySpring.tabSlide) {
            submittedSearchText = trimmedSearch
            selectedLessonIndex = 0
            learnerNotes = ""
            imageSearchAttempted = !trimmedSearch.isEmpty

            if trimmedSearch.isEmpty {
                webLessons = []
                imageSearchStatusMessage = nil
                isSearchingWeb = false
            }
        }
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)

        guard !trimmedSearch.isEmpty else { return }

        let requestID = UUID()
        activeSearchRequestID = requestID
        isSearchingWeb = true
        webLessons = []
        imageSearchStatusMessage = searchStartMessage(for: trimmedSearch)

        Task {
            let service = ImageLessonService()

            do {
                let fetchedLessons = try await service.searchLessons(
                    query: trimmedSearch,
                    providers: learningSettings.imageAPIProviders
                )

                await MainActor.run {
                    guard activeSearchRequestID == requestID, submittedSearchText == trimmedSearch else { return }
                    webLessons = fetchedLessons
                    isSearchingWeb = false

                    if fetchedLessons.isEmpty {
                        imageSearchStatusMessage = "No web images were returned for '\(trimmedSearch)'. Engify is showing backup lesson cards instead."
                    } else {
                        let providerLabel = fetchedLessons.first?.providerName ?? preferredConfiguredProviderName ?? "the web provider"
                        imageSearchStatusMessage = "Showing \(fetchedLessons.count) live image \(fetchedLessons.count == 1 ? "lesson" : "lessons") from \(providerLabel)."
                    }
                }
            } catch {
                await MainActor.run {
                    guard activeSearchRequestID == requestID, submittedSearchText == trimmedSearch else { return }
                    webLessons = []
                    isSearchingWeb = false
                    imageSearchStatusMessage = "\(error.localizedDescription) Engify is showing backup lessons in the meantime."
                }
            }
        }
    }

    private func clearSearch() {
        withAnimation(EngifySpring.tabSlide) {
            searchText = ""
            submittedSearchText = ""
            selectedLessonIndex = 0
            learnerNotes = ""
            webLessons = []
            imageSearchStatusMessage = nil
            imageSearchAttempted = false
            isSearchingWeb = false
        }
    }

    private func selectPreviousLesson() {
        guard !activeLessons.isEmpty else { return }
        let previousIndex = selectedLessonIndex == 0 ? activeLessons.count - 1 : selectedLessonIndex - 1
        updateSelection(to: previousIndex)
    }

    private func selectNextLesson() {
        guard !activeLessons.isEmpty else { return }
        let nextIndex = selectedLessonIndex == activeLessons.count - 1 ? 0 : selectedLessonIndex + 1
        updateSelection(to: nextIndex)
    }

    private func score(for lesson: PracticeImageLesson) -> Int {
        guard hasSubmittedSearch else { return 1 }

        let combinedText = [
            lesson.title,
            lesson.locationLabel,
            lesson.visualStyle,
            lesson.sceneDescription,
            lesson.searchTopics.joined(separator: " "),
            lesson.focusVocabulary.joined(separator: " ")
        ]
        .joined(separator: " ")
        .lowercased()

        return searchKeywords.reduce(into: 0) { score, keyword in
            if combinedText.contains(keyword) {
                score += 2
            }

            if lesson.searchTopics.contains(where: { $0.localizedCaseInsensitiveContains(keyword) }) {
                score += 3
            }

            if lesson.focusVocabulary.contains(where: { $0.localizedCaseInsensitiveContains(keyword) }) {
                score += 2
            }
        }
    }

    private func hydrateSubmittedSearchIfNeeded() {
        guard submittedSearchText.isEmpty else { return }

        let initialSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !initialSearch.isEmpty else { return }

        submittedSearchText = initialSearch
    }

    private var resultCountLabel: String {
        if isSearchingWeb {
            return "Searching for live image lessons..."
        }

        let sourceLabel = webLessons.isEmpty ? "backup" : "live"
        return "\(activeLessons.count) \(activeLessons.count == 1 ? "scene" : "scenes") ready • \(sourceLabel) results"
    }

    private func searchStartMessage(for query: String) -> String {
        if let preferredConfiguredProviderName {
            return "Searching \(preferredConfiguredProviderName) for '\(query)'."
        }

        return "Searching the web for '\(query)'."
    }

    private var summaryColor: Color {
        if filteredLessons.isEmpty && !normalizedSearchText.isEmpty && !isSearchingWeb && webLessons.isEmpty {
            return EngifyColors.coral
        }

        return EngifyColors.textSecondary
    }

    private var statusBannerIcon: String {
        if isSearchingWeb {
            return "network"
        }

        if !webLessons.isEmpty {
            return "checkmark.seal.fill"
        }

        return "exclamationmark.triangle.fill"
    }

    @ViewBuilder
    private func statusBanner(text: String, color: Color, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .padding(.top, 1)

            Text(text)
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct ImagePracticeResultCard: View {
    let lesson: PracticeImageLesson
    let accentColor: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ZStack(alignment: .topTrailing) {
                PracticeLessonImageView(
                    lesson: lesson,
                    accentColor: accentColor,
                    cornerRadius: 22
                )
                    .frame(width: 210, height: 132)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(accentColor.opacity(isSelected ? 0.32 : 0.14), lineWidth: 1)
                    )

                Text(lesson.locationLabel)
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(lesson.title)
                    .font(EngifyTypography.bodyStrong)
                    .foregroundStyle(EngifyColors.textPrimary)
                    .lineLimit(2)

                Text(lesson.visualStyle)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(Spacing.md)
        .frame(width: 238, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isSelected ? accentColor.opacity(0.08) : EngifyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accentColor.opacity(isSelected ? 0.24 : 0.10), lineWidth: 1)
        )
    }
}

private struct PracticeLessonImageView: View {
    let lesson: PracticeImageLesson
    let accentColor: Color
    let cornerRadius: CGFloat

    var body: some View {
        AsyncImage(url: lesson.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()

            case .failure:
                fallbackImage

            case .empty:
                loadingPlaceholder

            @unknown default:
                fallbackImage
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.24),
                            EngifyColors.surface,
                            accentColor.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            ProgressView()
                .tint(accentColor)
        }
    }

    private var fallbackImage: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.24),
                            EngifyColors.surface,
                            accentColor.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(accentColor.opacity(0.14))
                .frame(width: 110, height: 110)
                .offset(x: 18, y: 12)

            Image(systemName: lesson.systemImage)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(accentColor)
                .padding(Spacing.lg)
        }
    }
}

private struct ImageLessonAttributionView: View {
    let lesson: PracticeImageLesson
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Image source")
                .font(EngifyTypography.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textSecondary)

            if let providerName = lesson.providerName {
                HStack(spacing: Spacing.sm) {
                    Text("Powered by \(providerName)")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    if let providerURL = lesson.providerAttributionURL {
                        Link(destination: providerURL) {
                            Text("Visit provider")
                                .font(EngifyTypography.caption.weight(.semibold))
                                .foregroundStyle(accentColor)
                        }
                    }
                }
            }

            if let creatorName = lesson.creatorName, !creatorName.isEmpty {
                if let creatorProfileURL = lesson.creatorProfileURL {
                    Link(destination: creatorProfileURL) {
                        Text("Photo by \(creatorName)")
                            .font(EngifyTypography.caption.weight(.semibold))
                            .foregroundStyle(accentColor)
                    }
                } else {
                    Text("Photo by \(creatorName)")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                }
            }

            if let sourcePageURL = lesson.sourcePageURL {
                Link(destination: sourcePageURL) {
                    Text("Open original photo")
                        .font(EngifyTypography.caption.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DedicatedDialoguePracticeView: View {
    let accentColor: Color
    let scenarios: [PracticeDialogueScenario]
    @Binding var selectedScenarioIndex: Int
    @Binding var responseDraft: String
    let learningSettings: LearningSettingsManager
    let onComplete: () -> Void

    private var scenario: PracticeDialogueScenario {
        scenarios[selectedScenarioIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            PracticeDetailHeader(
                title: "Roleplay Dialogues",
                subtitle: "Train useful English for everyday moments with guided openings, phrase banks, and your own response draft."
            )

            EngifyCard(tint: accentColor) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Scenario selector")
                                .font(EngifyTypography.caption.weight(.semibold))
                                .foregroundStyle(accentColor)
                                .textCase(.uppercase)

                            Text("Scenario \(selectedScenarioIndex + 1) of \(scenarios.count)")
                                .font(EngifyTypography.body)
                                .foregroundStyle(EngifyColors.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Menu {
                            ForEach(scenarios.indices, id: \.self) { index in
                                Button(scenarios[index].title) {
                                    updateSelection(to: index)
                                }
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text(scenario.title)
                                    .font(EngifyTypography.bodyStrong)
                                    .foregroundStyle(EngifyColors.textPrimary)
                                    .lineLimit(1)

                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(accentColor)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(accentColor.opacity(0.10))
                            .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: Spacing.md) {
                        SecondaryButton(
                            title: "Previous",
                            systemImage: "arrow.left",
                            action: selectPreviousScenario,
                            size: .large
                        )

                        SecondaryButton(
                            title: "Next",
                            systemImage: "arrow.right",
                            action: selectNextScenario,
                            size: .large
                        )
                    }
                }
            }

            EngifyCard {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(accentColor.opacity(0.14))
                                .frame(width: 72, height: 72)

                            Image(systemName: scenario.systemImage)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(accentColor)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(scenario.setting)
                                .font(EngifyTypography.caption.weight(.semibold))
                                .foregroundStyle(accentColor)
                                .textCase(.uppercase)

                            Text(scenario.title)
                                .font(EngifyTypography.screenTitle)
                                .foregroundStyle(EngifyColors.textPrimary)

                            Text(scenario.goal)
                                .font(EngifyTypography.body)
                                .foregroundStyle(EngifyColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Conversation opener")
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        Text("\"\(scenario.partnerOpeningLine)\"")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundStyle(EngifyColors.textPrimary)
                            .padding(Spacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(accentColor.opacity(0.08))
                            )
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Response ideas")
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        ForEach(Array(scenario.responseIdeas.enumerated()), id: \.offset) { index, idea in
                            HStack(alignment: .top, spacing: Spacing.md) {
                                Image(systemName: "\(index + 1).circle.fill")
                                    .foregroundStyle(accentColor)

                                Text(idea)
                                    .font(EngifyTypography.body)
                                    .foregroundStyle(EngifyColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Useful phrases")
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        FlexibleBadgeRow(items: scenario.usefulPhrases, tint: accentColor)
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Draft your response")
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        if #available(iOS 16.0, *) {
                            TextEditor(text: $responseDraft)
                                .scrollContentBackground(.hidden)
                                .font(EngifyTypography.body)
                                .frame(minHeight: 150)
                                .padding(Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(accentColor.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(accentColor.opacity(0.16), lineWidth: 1)
                                )
                        } else {
                            // Fallback on earlier versions
                        }

                        Text(scenario.confidenceTip)
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    PrimaryButton(
                        title: "Complete Dialogue Practice",
                        systemImage: "checkmark.circle.fill",
                        action: onComplete,
                        feedbackEvent: .successPop
                    )
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private func updateSelection(to index: Int) {
        guard scenarios.indices.contains(index) else { return }

        withAnimation(EngifySpring.tabSlide) {
            selectedScenarioIndex = index
            responseDraft = ""
        }
        EngifyFeedback.shared.play(.tabSwitch, settings: learningSettings)
    }

    private func selectPreviousScenario() {
        let previousIndex = selectedScenarioIndex == 0 ? scenarios.count - 1 : selectedScenarioIndex - 1
        updateSelection(to: previousIndex)
    }

    private func selectNextScenario() {
        let nextIndex = selectedScenarioIndex == scenarios.count - 1 ? 0 : selectedScenarioIndex + 1
        updateSelection(to: nextIndex)
    }
}

private struct FlexibleBadgeRow: View {
    let items: [String]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(chunkedItems, id: \.self) { row in
                HStack(spacing: Spacing.sm) {
                    ForEach(row, id: \.self) { item in
                        VocabularyBadge(text: item, tint: tint)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunkedItems: [[String]] {
        stride(from: 0, to: items.count, by: 2).map { index in
            Array(items[index..<min(index + 2, items.count)])
        }
    }
}

private struct DedicatedQuizView: View {
    let accentColor: Color
    let theme: ThemeManager
    let learningSettings: LearningSettingsManager
    let questions: [QuizQuestion]
    @Binding var quizAnswers: [UUID: Int]
    @Binding var showQuizResult: Bool
    let quizScore: Int
    let scoreColor: Color
    let onSelectAnswer: (QuizQuestion, Int) -> Void
    let onCheckScore: () -> Void
    let onRefresh: () -> Void
    let onAppear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            PracticeDetailHeader(
                title: "Interactive Quizzes",
                subtitle: "Run a tight set of rapid-fire questions, then see exactly how your recall held up."
            )

            EngifyCard(tint: accentColor) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Quiz set")
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)

                        Text("\(questions.count) questions ready")
                            .font(EngifyTypography.cardTitle)
                            .foregroundStyle(EngifyColors.textPrimary)
                    }

                    Spacer(minLength: 0)

                    SecondaryButton(
                        title: "New Quiz",
                        systemImage: "arrow.clockwise",
                        action: onRefresh,
                        feedbackEvent: .tabSwitch
                    )
                }
            }

            ForEach(questions) { question in
                MultipleChoiceQuestionCard(
                    question: question,
                    selectedAnswer: quizAnswers[question.id],
                    revealAnswer: showQuizResult && quizAnswers[question.id] != nil,
                    showsExplanation: learningSettings.showGrammarCorrections,
                    onSelect: { selected in
                        onSelectAnswer(question, selected)
                    }
                )
            }

            EngifyCard(tint: accentColor) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    PrimaryButton(
                        title: showQuizResult ? "Score Locked In" : "Check Score",
                        systemImage: "checkmark.circle.fill",
                        action: onCheckScore,
                        isDisabled: showQuizResult,
                        feedbackEvent: .successPop
                    )
                    .environmentObject(theme)

                    if showQuizResult {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(alignment: .center, spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Your Score")
                                        .font(EngifyTypography.caption)
                                        .foregroundStyle(EngifyColors.textSecondary)

                                    Text("\(quizScore)/\(questions.count)")
                                        .font(EngifyTypography.cardTitle)
                                        .foregroundStyle(EngifyColors.textPrimary)
                                }

                                Spacer(minLength: 0)

                                QuizScoreIndicator(
                                    score: quizScore,
                                    total: max(1, questions.count),
                                    color: scoreColor
                                )
                            }

                            Text(
                                tutorResultMessage
                            )
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)

                            if learningSettings.explanationDepth != "simple" {
                                Text(nextStepMessage)
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                            }

                            if learningSettings.explanationDepth == "detailed" {
                                Text("Correct answers: \(quizScore). Missed answers: \(max(0, questions.count - quizScore)).")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .onAppear(perform: onAppear)
    }

    private var tutorResultMessage: String {
        guard quizScore != questions.count else {
            return "Perfect! You're mastering these concepts."
        }

        switch learningSettings.correctionStyle {
        case "strict":
            return learningSettings.showGrammarCorrections
                ? "Accuracy first. Review the corrections and fix the missed patterns before moving on."
                : "Accuracy first. Try another round and aim for fewer mistakes."
        case "gentle":
            return learningSettings.showGrammarCorrections
                ? "Nice effort. Review the corrections and give it another calm try."
                : "Nice effort. Every round helps the pattern feel more natural."
        default:
            return learningSettings.showGrammarCorrections
                ? "Keep practicing. Review the corrections and try again."
                : "Keep practicing. Every attempt builds your skills."
        }
    }

    private var nextStepMessage: String {
        switch learningSettings.explanationDepth {
        case "detailed":
            return "Next step: focus on one missed rule, say one correct sentence aloud, then retake the quiz."
        case "balanced":
            return "Next step: revisit one missed pattern, then try again."
        default:
            return ""
        }
    }
}

private struct QuizScoreIndicator: View {
    let score: Int
    let total: Int
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.20), lineWidth: 6)
                .frame(width: 68, height: 68)

            Circle()
                .trim(from: 0, to: CGFloat(score) / CGFloat(total))
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 68, height: 68)
                .rotationEffect(.degrees(-90))

            Text("\(Int(Double(score) / Double(total) * 100))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
    }
}
