import SwiftUI

/// A sweeping shimmer overlay modifier for skeleton loading states.
///
/// WHAT IT DOES:
/// - Adds a white linear gradient sweep (left → right → left) over content
///   to create a shimmer/skeleton effect during loading.
/// - ShimmerModifier: the ViewModifier implementing the animation.
/// - .shimmer(): convenience View extension applying the modifier.
/// - SkeletonSuggestionRow: a suggestion list placeholder with shimmer applied.
///
/// WHEN IT SHOWS:
/// - SkeletonSuggestionRow is used in DictionaryView's suggestionsDropdown
///   while viewModel.isSuggestionsLoading is true (3 skeleton rows shown).
///
/// HOW IT WORKS:
/// - The overlay gradient goes from fully transparent → 30% white → transparent.
/// - offset animates from -300 to +300 points in a 1.5s linear repeatForever loop.
/// - .onAppear starts the animation; the modifier disables when isActive = false.
struct ShimmerModifier: ViewModifier {
    @State private var isShimmering = false
    let isActive: Bool
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        shimmerColor.opacity(0),
                        shimmerColor.opacity(colorScheme == .dark ? 0.24 : 0.30),
                        shimmerColor.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isShimmering ? 300 : -300)
                .animation(
                    isActive ? Animation.linear(duration: 1.5).repeatForever(autoreverses: false) : nil,
                    value: isShimmering
                )
            )
            .onAppear { isShimmering = true }
    }

    private var shimmerColor: Color {
        colorScheme == .dark ? EngifyColors.surfaceMuted : EngifyColors.surface
    }
}

extension View {
    /// Apply shimmer effect for skeleton loaders.
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

/// Skeleton loader row for dictionary suggestions.
/// Shows a placeholder while suggestions are loading.
struct SkeletonSuggestionRow: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 120, height: 10)
            }
            Spacer()
            
            Image(systemName: "arrow.up.left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textSecondary)
                .opacity(0)
        }
        .padding(12)
        .shimmer()
    }
}

struct SkeletonSuggestionRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            SkeletonSuggestionRow()
            SkeletonSuggestionRow()
            SkeletonSuggestionRow()
        }
        .padding()
        .background(EngifyAppBackground())
    }
}
