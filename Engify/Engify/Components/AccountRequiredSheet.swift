import SwiftUI

struct AccountRequiredSheet: View {
    let context: AccountRequiredContext
    let onSignIn: () -> Void
    let onMaybeLater: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ZStack {
            EngifyColors.surface
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                EngifyIconBadge(systemImage: "lock.fill", tint: theme.accentColor, size: 58)

                VStack(spacing: Spacing.sm) {
                    Text("Unlock Unlimited Access")
                        .font(EngifyTypography.cardTitle)
                        .foregroundStyle(theme.accentColor)
                        .multilineTextAlignment(.center)

                    Text("Create a free account or sign in to save vocabulary words, practice active speaking exercises, and save your daily learning streaks!")
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Text(context.feature.reason)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(
                    title: "Sign In / Sign Up Now",
                    systemImage: "arrow.right.circle.fill",
                    action: {
                        dismiss()
                        onSignIn()
                    }
                )
                .environmentObject(theme)

                Button("Maybe Later") {
                    dismiss()
                    onMaybeLater()
                }
                .buttonStyle(.plain)
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
            }
            .padding(.top, Spacing.xl)
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xl)
        }
    }
}
