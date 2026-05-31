import SwiftUI

struct PracticeView: View {
    @State private var activePracticeSheet: PracticeRoute?
    @State private var selectedGrammarTopic = 0
    @State private var speakingHintVisible = false
    @State private var quizAnswers: [UUID: Int] = [:]
    @State private var showQuizResult = false
    @State private var currentQuizQuestions: [QuizQuestion] = []
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @State private var showBadge = false
    @State private var showSettingsSheet = false

    var body: some View {
        EngifyScreenScroll {
            globalHeader
            routedContent
        }
        .overlay {
            if showBadge {
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
                    speakingHintVisible: $speakingHintVisible
                )

            case .grammar:
                DedicatedGrammarLessonView(
                    accentColor: theme.accentColor,
                    grammarTopics: EngifySampleData.grammarTopics,
                    selectedTopicIndex: $selectedGrammarTopic,
                    learningSettings: learningSettings
                )

            case .quiz:
                DedicatedQuizView(
                    accentColor: theme.accentColor,
                    theme: theme,
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
        showQuizResult = true
        let earnedXP = quizScore * 5

        if earnedXP > 0 {
            gamification.earnXP(earnedXP)
        }

        if quizScore == currentQuizQuestions.count, !currentQuizQuestions.isEmpty {
            gamification.completeLesson(type: .practice, xpEarned: earnedXP, lingotsEarned: 1)
            showBadge = true
        }
    }

    private func refreshQuiz() {
        currentQuizQuestions = randomizedQuizQuestions()
        quizAnswers.removeAll()
        showQuizResult = false
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
                                            colors: [EngifyColors.sage, accentColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 150, height: 150)
                                    .shadow(color: accentColor.opacity(0.28), radius: 18, x: 0, y: 14)

                                Image(systemName: "mic.fill")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(.white)
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

                    Group {
                        if speakingHintVisible {
                            HStack(alignment: .top, spacing: Spacing.md) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(accentColor)

                                Text("Microphone recording and pronunciation feedback will be available in a future update.")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
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

                        Text(topic.explanation)
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

private struct DedicatedQuizView: View {
    let accentColor: Color
    let theme: ThemeManager
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
                                quizScore == questions.count
                                    ? "Perfect! You're mastering these concepts."
                                    : "Keep practicing. Every attempt builds your skills."
                            )
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)
                        }
                    }
                }
            }
        }
        .onAppear(perform: onAppear)
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
