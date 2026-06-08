import SwiftUI

struct OnboardingSurveyView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var surveyManager: OnboardingSurveyManager

    @State private var learningGoal = "daily"
    @State private var englishLevel = "beginner"
    @State private var dailyStudyMinutes = 15
    @State private var biggestChallenge = "speaking"
    @State private var isSubmitting = false

    let onComplete: () -> Void

    private let goals: [(key: String, title: String)] = [
        ("daily", "Daily communication"),
        ("travel", "Travel"),
        ("work", "Work"),
        ("study", "Study"),
        ("exam", "IELTS / TOEFL")
    ]

    private let levels: [(key: String, title: String)] = [
        ("beginner", "Beginner"),
        ("intermediate", "Intermediate"),
        ("advanced", "Advanced")
    ]

    private let challenges: [(key: String, title: String)] = [
        ("speaking", "Speaking"),
        ("listening", "Listening"),
        ("grammar", "Grammar"),
        ("vocabulary", "Vocabulary"),
        ("confidence", "Confidence")
    ]

    var body: some View {
        EngifyScreenScroll(alignment: .center, spacing: Spacing.xl, bottomInset: 40) {
            VStack(spacing: Spacing.xl) {
                header
                surveyCard
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.14))
                    .frame(width: 92, height: 92)

                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(theme.accentColor)
            }

            VStack(spacing: Spacing.sm) {
                Text("Help Us Personalize Engify")
                    .font(EngifyTypography.screenTitle)
                    .foregroundStyle(EngifyColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Answer a few quick questions so we can shape the learning experience around your goals.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 20)
    }

    private var surveyCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                surveySection(
                    title: "Primary learning goal",
                    subtitle: "What do you want English to help you do most?"
                ) {
                    selectionGrid(
                        items: goals,
                        selectedKey: learningGoal,
                        onSelect: { learningGoal = $0 }
                    )
                }

                surveySection(
                    title: "Current level",
                    subtitle: "Choose the level that feels closest to you."
                ) {
                    selectionGrid(
                        items: levels,
                        selectedKey: englishLevel,
                        onSelect: { englishLevel = $0 }
                    )
                }

                surveySection(
                    title: "Daily study time",
                    subtitle: "How much time can you usually spend each day?"
                ) {
                    Picker("Daily study minutes", selection: $dailyStudyMinutes) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("20 min").tag(20)
                        Text("30 min").tag(30)
                    }
                    .pickerStyle(.segmented)
                }

                surveySection(
                    title: "Biggest challenge",
                    subtitle: "Which part of English feels hardest right now?"
                ) {
                    selectionGrid(
                        items: challenges,
                        selectedKey: biggestChallenge,
                        onSelect: { biggestChallenge = $0 }
                    )
                }

                PrimaryButton(
                    title: isSubmitting ? "Saving..." : "Continue",
                    systemImage: "arrow.right.circle.fill",
                    action: submitSurvey,
                    isDisabled: isSubmitting
                )
            }
        }
    }

    private func surveySection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(EngifyTypography.headline)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text(subtitle)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
    }

    private func selectionGrid(
        items: [(key: String, title: String)],
        selectedKey: String,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(items, id: \.key) { item in
                Button {
                    onSelect(item.key)
                    EngifyFeedback.shared.play(.tabSwitch)
                } label: {
                    HStack(spacing: Spacing.md) {
                        Text(item.title)
                            .font(EngifyTypography.bodyStrong)
                            .foregroundStyle(EngifyColors.textPrimary)

                        Spacer(minLength: 0)

                        Image(systemName: selectedKey == item.key ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selectedKey == item.key ? theme.accentColor : EngifyColors.textSecondary.opacity(0.45))
                    }
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func submitSurvey() {
        guard !isSubmitting else { return }

        isSubmitting = true

        let response = OnboardingSurveyResponse(
            learningGoal: learningGoal,
            englishLevel: englishLevel,
            dailyStudyMinutes: dailyStudyMinutes,
            biggestChallenge: biggestChallenge
        )

        Task {
            await surveyManager.submit(response)
            await MainActor.run {
                EngifyFeedback.shared.play(.successPop)
                isSubmitting = false
                onComplete()
            }
        }
    }
}
