import SwiftUI

struct IntroView: View {
    @EnvironmentObject private var theme: ThemeManager

    let onContinue: () -> Void

    var body: some View {
        EngifyScreenScroll(bottomInset: 40) {
            heroSection
            featureSection
            actionsSection
        }
    }

    private var heroSection: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: 8)

            EngifyLogoView()
                .frame(height: 116)

            VStack(spacing: Spacing.sm) {
                Text("Unlock Your English Potential")
                    .font(EngifyTypography.hero)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text("A friendly place to build vocabulary, read news, and practice every day.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    private var featureSection: some View {
        LearningCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                IntroFeatureRow(
                    icon: "book.closed.fill",
                    title: "Daily vocabulary",
                    subtitle: "Learn small, useful word sets that fit real life."
                )
                IntroFeatureRow(
                    icon: "newspaper.fill",
                    title: "Simple reading",
                    subtitle: "Practice with approachable articles and guided summaries."
                )
                IntroFeatureRow(
                    icon: "person.text.rectangle",
                    title: "Quick practice",
                    subtitle: "Build confidence with quizzes and speaking prompts."
                )
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: Spacing.md) {
            PrimaryButton(title: "Start Learning", systemImage: "arrow.right.circle.fill", action: {
                onContinue()
            })
            .environmentObject(theme)

            SecondaryButton(title: "Continue to Sign In", systemImage: "sparkles", action: {
                onContinue()
            })
        }
    }
}

private struct IntroFeatureRow: View {
    @EnvironmentObject private var theme: ThemeManager

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            EngifyIconBadge(systemImage: icon, tint: theme.accentColor, size: 40)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(EngifyTypography.bodyStrong)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text(subtitle)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    IntroView(onContinue: {})
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
}
