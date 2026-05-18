import SwiftUI

/// A themed loading indicator with a message label.
///
/// WHAT IT SHOWS:
/// - A CircularProgressView styled with the app's accent color, scaled to 1.2x.
/// - A label below showing the loading message in secondary color.
///
/// WHEN IT SHOWS:
/// - Not currently used directly, but available as a reusable loading state
///   for any async operation that needs user-facing context.
struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        EngifyLoadingCard(title: "Loading...", message: message)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .padding()
    }
}
