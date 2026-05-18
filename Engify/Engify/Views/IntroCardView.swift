import SwiftUI

/// Model for a single intro feature card (used by IntroPagerView).
struct IntroCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let primaryColor: Color
    let secondaryColor: Color
}

/// A single card view used by IntroPagerView to display one feature highlight.
///
/// WHAT IT SHOWS:
/// - A gradient circle on the left containing a SF Symbol icon.
/// - Title and subtitle text aligned to the right of the icon.
/// - A description paragraph below the header.
/// - Card background with subtle shadow for depth.
///
/// WHEN IT SHOWS:
/// - Rendered by IntroPagerView one card at a time based on the current page index.
struct IntroCardView: View {
    let card: IntroCard

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [card.primaryColor, card.secondaryColor]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 72, height: 72)
                        .shadow(color: card.primaryColor.opacity(0.35), radius: 12, x: 0, y: 6)

                    Image(systemName: card.systemImage)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(card.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(card.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(card.primaryColor)
                }

                Spacer()
            }

            Text(card.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.md)

            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 6)
        )
    }
}

#if DEBUG
struct IntroCardView_Previews: PreviewProvider {
    static var previews: some View {
        IntroCardView(card: IntroCard(
            title: "Welcome to Engify",
            subtitle: "Learn English naturally",
            description: "Bite-sized lessons, smart dictionary suggestions, and fun quizzes to keep you motivated.",
            systemImage: "sparkles",
            primaryColor: Color(red: 0.25, green: 0.55, blue: 0.95),
            secondaryColor: Color(red: 0.28, green: 0.74, blue: 0.85)
        ))
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif
