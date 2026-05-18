import SwiftUI

/// The Engify brand logo: graduation cap icon inside a gradient rounded square.
///
/// WHAT IT SHOWS:
/// - A rounded rectangle with a two-stop gradient fill (accentColor at 95% → 55% opacity).
/// - A graduation cap SF Symbol centered inside.
/// - "Engify" text below the icon.
/// - Soft glow shadow beneath the logo square.
///
/// WHEN IT SHOWS:
/// - IntroView: centered above the tagline text.
/// - LoginView: hero section at the top of the form.
/// - Can be reused anywhere the brand logo needs to appear.
struct EngifyLogoView: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.accentColor.opacity(0.95), theme.accentColor.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 116, height: 116)
                .shadow(color: theme.accentColor.opacity(0.18), radius: 18, x: 0, y: 12)

            VStack(spacing: 6) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Text("Engify")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel("Engify logo")
    }
}
