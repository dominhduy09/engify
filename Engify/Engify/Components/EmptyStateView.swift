import SwiftUI

/// Centered placeholder view shown when a list or content is empty.
///
/// WHAT IT SHOWS:
/// - A centered column: SF Symbol icon (customizable), bold title, and a
///   secondary-color message text with horizontal padding for multiline alignment.
///
/// WHEN IT SHOWS:
/// - Not currently used in any view, but available for future empty states
///   (e.g., no saved words, no search results after API failure, no articles).
///
/// HOW IT WORKS:
/// - Pass `title`, `message`, and optionally `systemImage` as init parameters.
struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String = "sparkles"

    var body: some View {
        EngifyStateCard(
            title: title,
            message: message,
            systemImage: systemImage
        )
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(title: "No saved words", message: "Save words to see them here.")
            .padding()
    }
}
