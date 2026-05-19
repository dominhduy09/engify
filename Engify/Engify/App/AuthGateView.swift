import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        Group {
            switch authManager.authState {
            case .restoring:
                loadingState
            case .authenticated:
                MainTabView()
            case .unauthenticated:
                MainTabView()
            }
        }
    }

    private var loadingState: some View {
        EngifyScreenScroll(alignment: .center, spacing: Spacing.lg, bottomInset: 40) {
            VStack(spacing: Spacing.lg) {
                EngifyLogoView()
                    .frame(height: 112)

                Text("Restoring your session...")
                    .font(EngifyTypography.sectionTitle)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text("Engify is checking your secure Supabase session before opening the app.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .multilineTextAlignment(.center)

                LoadingView(message: "Checking account")
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        }
    }
}
