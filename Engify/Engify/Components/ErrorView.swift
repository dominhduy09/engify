import SwiftUI

/// Error state placeholder with warning icon, message, and optional retry button.
///
/// WHAT IT SHOWS:
/// - A yellow exclamationmark.triangle.fill icon at the top.
/// - Title and message text below.
/// - A "Try again" bordered prominent button if a retry closure is provided.
///
/// WHEN IT SHOWS:
/// - Not currently used directly, but available for error states across
///   network-bound views (Dictionary, News) in place of inline error cards.
///
/// HOW IT WORKS:
/// - `retry` is an optional () -> Void closure; the button only appears if set.
struct ErrorView: View {
    var title: String
    var message: String
    var retry: (() -> Void)?

    var body: some View {
        EngifyStateCard(
            title: title,
            message: message,
            systemImage: "exclamationmark.triangle.fill",
            tone: .warning,
            actionTitle: retry == nil ? nil : "Try Again",
            action: retry
        )
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(title: "Oops", message: "Something went wrong.")
            .padding()
    }
}
