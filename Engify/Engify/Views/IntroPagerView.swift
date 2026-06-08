import SwiftUI

/// Swipeable card pager used inside IntroView for feature showcase pages.
///
/// WHAT IT DOES:
/// - Shows one IntroCard at a time from a provided cards array.
/// - Page indicator dots at the bottom (larger/darker dot = current page).
/// - Previous/Next buttons with disabled state on first/last card.
/// - "Done" label on the last card's Next button.
///
/// WHEN IT SHOWS:
/// - Embedded inside IntroView but currently bypassed — IntroView renders
///   feature rows directly instead of paging through cards.
///
/// HOW IT WORKS:
/// - ForEach with index matching against @State index to show only the active card.
/// - .transition(.asymmetric(...)) provides a slide-left/right animation between cards.
/// - .animation(.spring(...)) smooths the index change.
struct IntroPagerView: View {
    @State private var index: Int = 0
    let cards: [IntroCard]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Card area with animated transitions
            ZStack {
                ForEach(cards.indices, id: \ .self) { i in
                    if i == index {
                        IntroCardView(card: cards[i])
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            .id(i)
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: index)
            .frame(maxHeight: 300)

            // Pager indicator
            HStack(spacing: Spacing.sm) {
                ForEach(cards.indices, id: \ .self) { i in
                    Circle()
                        .fill(i == index ? EngifyColors.textPrimary : EngifyColors.textSecondary.opacity(0.4))
                        .frame(width: i == index ? 10 : 6, height: i == index ? 10 : 6)
                }
            }

            // Controls
            HStack(spacing: Spacing.md) {
                Button(action: previous) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .foregroundStyle(EngifyColors.textPrimary)
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(EngifyColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(EngifyColors.border.opacity(0.85), lineWidth: 1)
                    )
                }
                .disabled(index == 0)

                Spacer()

                Button(action: next) {
                    HStack {
                        Text(index == cards.count - 1 ? "Done" : "Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.xl)
                    .background(LinearGradient(colors: [Color(red: 0.25, green: 0.55, blue: 0.95), Color(red: 0.28, green: 0.74, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundStyle(EngifyColors.textInverse)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding()
    }

    private func previous() {
        guard index > 0 else { return }
        withAnimation { index -= 1 }
    }

    private func next() {
        if index < cards.count - 1 {
            withAnimation { index += 1 }
        } else {
            // last card action, close intro or notify parent (left intentionally simple)
            // In a real app you'd dismiss the intro or mark onboarding completed.
        }
    }
}

#if DEBUG
struct IntroPagerView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = [
            IntroCard(title: "Welcome to Engify", subtitle: "Start your journey", description: "Bite-sized daily lessons that fit your schedule.", systemImage: "sparkles", primaryColor: Color(red: 0.25, green: 0.55, blue: 0.95), secondaryColor: Color(red: 0.28, green: 0.74, blue: 0.85)),
            IntroCard(title: "Smart Dictionary", subtitle: "Look up words quickly", description: "Get definitions, phonetics, and example sentences on the fly.", systemImage: "text.magnifyingglass", primaryColor: Color(red: 0.7, green: 0.4, blue: 0.95), secondaryColor: Color(red: 0.85, green: 0.5, blue: 1.0)),
            IntroCard(title: "Practice & Quizzes", subtitle: "Reinforce learning", description: "Interactive quizzes and speaking exercises to boost retention.", systemImage: "target", primaryColor: Color(red: 0.4, green: 0.85, blue: 0.5), secondaryColor: Color(red: 0.5, green: 0.95, blue: 0.6))
        ]
        IntroPagerView(cards: sample)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
