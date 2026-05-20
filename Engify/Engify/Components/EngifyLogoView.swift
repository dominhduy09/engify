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
    var body: some View {
        Image("EngifyBrandLogo")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityLabel("Engify logo")
    }
}
