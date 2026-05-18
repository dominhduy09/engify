import SwiftUI

/// A friendly rounded card used in the onboarding IntroView.
///
/// WHAT IT DOES:
/// - Wraps any content in a rounded rectangle with system background fill,
///   a subtle border, and a soft shadow tinted by the theme accent color.
/// - Adapts to light/dark mode using the system background color.
///
/// WHEN IT SHOWS:
/// - Currently used only in IntroView to wrap the three feature highlight rows.
///
/// HOW IT WORKS:
/// - Uses Color(.secondarySystemBackground) in dark mode, Color(.systemBackground) in light.
/// - The border is a very subtle 6% opacity primary color stroke.
struct LearningCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack {
            content()
        }
        .modifier(LearningCardSurface())
    }
}

private struct LearningCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        EngifyCard {
            content
        }
    }
}

struct LearningCard_Previews: PreviewProvider {
    static var previews: some View {
        LearningCard {
            VStack(alignment: .leading) {
                Text("Welcome")
                    .font(.headline)
                Text("A friendly card for learners.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .environmentObject(ThemeManager())
    }
}
