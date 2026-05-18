import SwiftUI

struct PracticeView: View {
    @State private var selectedGrammarTopic = 0
    @State private var speakingHintVisible = false
    @State private var quizAnswers: [UUID: Int] = [:]
    @State private var showQuizResult = false
    @State private var currentQuizQuestions: [QuizQuestion] = []
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gamification: GamificationManager
    @State private var showBadge = false
    @State private var showSettingsSheet = false

    var body: some View {
        EngifyScreenScroll {
            globalHeader
            speakingSection
            grammarSection
            quizSection
        }
        .tabTransition()
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
        .onAppear {
            if currentQuizQuestions.isEmpty {
                refreshQuiz()
            }
        }
    }

    private var globalHeader: some View {
        EngifyGlobalTabHeader(
            title: "Practice",
            subtitle: "Speaking, grammar, and quiz reps",
            showSettings: $showSettingsSheet
        )
    }
    private var speakingSection: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                HStack(spacing: Spacing.md) {
                    EngifyIconBadge(systemImage: "mic.fill", tint: theme.accentColor)
                    Text("Speaking Practice")
                        .font(EngifyTypography.sectionTitle)
                        .foregroundStyle(EngifyColors.textPrimary)
                }

                Text(EngifySampleData.speakingSentence)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(EngifyColors.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                SecondaryButton(
                    title: "Start Speaking",
                    systemImage: "waveform",
                    action: { speakingHintVisible.toggle() }
                )

                if speakingHintVisible {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(theme.accentColor)

                        Text("Microphone recording and pronunciation feedback will be available in a future update.")
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Spacing.md)
                    .background(theme.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var grammarSection: some View {
        let topic = EngifySampleData.grammarTopics[selectedGrammarTopic]

        return EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.cardGap) {
                HStack(spacing: Spacing.md) {
                    EngifyIconBadge(systemImage: "book.fill", tint: theme.accentColor)
                    Text("Grammar Lesson")
                        .font(EngifyTypography.sectionTitle)
                        .foregroundStyle(EngifyColors.textPrimary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(EngifySampleData.grammarTopics.indices, id: \.self) { index in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    selectedGrammarTopic = index
                                }
                            } label: {
                                Text(EngifySampleData.grammarTopics[index].title)
                                    .font(EngifyTypography.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .foregroundStyle(selectedGrammarTopic == index ? EngifyColors.textInverse : theme.accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedGrammarTopic == index ? theme.accentColor : theme.accentColor.opacity(0.10))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(topic.title)
                        .font(EngifyTypography.cardTitle)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(topic.explanation)
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ForEach(topic.examples, id: \.self) { example in
                            HStack(alignment: .top, spacing: Spacing.md) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(theme.accentColor)

                                Text(example)
                                    .font(EngifyTypography.body)
                                    .foregroundStyle(EngifyColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            EngifySectionHeader(
                title: "Quick Quiz",
                subtitle: "Turn grammar and vocabulary into confident recall."
            )

            HStack(spacing: Spacing.md) {
                Text("\(currentQuizQuestions.count) questions")
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                Spacer(minLength: 0)
            }

            ForEach(currentQuizQuestions) { question in
                MultipleChoiceQuestionCard(
                    question: question,
                    selectedAnswer: quizAnswers[question.id],
                    revealAnswer: showQuizResult && quizAnswers[question.id] != nil,
                    onSelect: { [weak gamification] selected in
                        quizAnswers[question.id] = selected
                        if selected != question.answerIndex {
                            gamification?.loseHeart()
                        }
                    }
                )
            }

            EngifyCard(tint: theme.accentColor) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    PrimaryButton(title: "Check Score", systemImage: "checkmark.circle.fill", action: {
                        showQuizResult = true
                        let earnedXP = quizScore * 5
                        if earnedXP > 0 {
                            gamification.earnXP(earnedXP)
                        }
                        if quizScore == currentQuizQuestions.count {
                            gamification.completeLesson(type: .practice, xpEarned: earnedXP, lingotsEarned: 1)
                            showBadge = true
                        }
                    })
                    .environmentObject(theme)

                    if showQuizResult {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(alignment: .center, spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Your Score")
                                        .font(EngifyTypography.caption)
                                        .foregroundStyle(EngifyColors.textSecondary)

                                    Text("\(quizScore)/\(currentQuizQuestions.count)")
                                        .font(EngifyTypography.cardTitle)
                                        .foregroundStyle(EngifyColors.textPrimary)
                                }

                                Spacer(minLength: 0)
                                scoreIndicator
                            }

                            Text(
                                quizScore == currentQuizQuestions.count
                                    ? "Perfect! You're mastering these concepts."
                                    : "Keep practicing. Every attempt builds your skills."
                            )
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)

                            SecondaryButton(title: "New Quiz", systemImage: "arrow.clockwise", action: refreshQuiz)
                        }
                    }
                }
            }
        }
    }

    private var scoreIndicator: some View {
        ZStack {
            Circle()
                .stroke(scoreColor.opacity(0.20), lineWidth: 6)
                .frame(width: 68, height: 68)

            Circle()
                .trim(from: 0, to: CGFloat(quizScore) / CGFloat(max(1, currentQuizQuestions.count)))
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 68, height: 68)
                .rotationEffect(.degrees(-90))

            Text("\(Int(Double(quizScore) / Double(max(1, currentQuizQuestions.count)) * 100))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(scoreColor)
        }
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

    private func refreshQuiz() {
        let questionCount = min(5, EngifySampleData.practiceQuizQuestions.count)
        currentQuizQuestions = EngifySampleData.practiceQuizQuestions.shuffled().prefix(questionCount).map { $0 }
        quizAnswers.removeAll()
        showQuizResult = false
    }
}
