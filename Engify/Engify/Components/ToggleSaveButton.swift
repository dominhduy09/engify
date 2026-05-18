import SwiftUI

/// A bookmark toggle button for DictionaryEntry items.
///
/// WHAT IT DOES:
/// - Shows a filled bookmark icon when the entry is saved, outline when not.
/// - Tapping calls savedWordsManager.toggleSaved(entry) and triggers spring animation + haptic.
/// - Scale animates briefly (1.1x) on tap for tactile feedback.
///
/// WHEN IT SHOWS:
/// - Appears in DictionaryView's entry header, next to the audio pronunciation button.
///
/// HOW IT WORKS:
/// - Reads savedWordsManager.isSaved(entry) to determine icon and color.
/// - Uses ThemeManager for the active accent color on the bookmark icon.
/// - Spring animation via withAnimation + 0.3s async reset of isAnimating flag.
struct ToggleSaveButton: View {
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @EnvironmentObject private var theme: ThemeManager
    
    let entry: DictionaryEntry
    @State private var isAnimating = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
                savedWordsManager.toggleSaved(entry)
            }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: savedWordsManager.isSaved(entry) ? "bookmark.fill" : "bookmark")
                Text(savedWordsManager.isSaved(entry) ? "Saved" : "Save")
            }
            .font(EngifyTypography.caption.weight(.semibold))
            .foregroundStyle(savedWordsManager.isSaved(entry) ? theme.accentColor : EngifyColors.textSecondary)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 42)
            .background((savedWordsManager.isSaved(entry) ? theme.accentColor : EngifyColors.border).opacity(0.12))
            .clipShape(Capsule())
            .scaleEffect(isAnimating ? 1.06 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ToggleSaveButton(
        entry: DictionaryEntry(
            word: "test",
            phonetic: "/test/",
            audioURL: nil,
            partOfSpeech: "noun",
            definition: "A procedure to assess functionality",
            example: "This is a test",
            vietnameseMeaning: "Bài kiểm tra"
        )
    )
    .environmentObject(SavedWordsManager())
    .environmentObject(ThemeManager())
    .padding()
}
