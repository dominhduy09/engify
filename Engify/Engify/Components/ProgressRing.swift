import SwiftUI

/// Animated circular progress ring with percentage label.
///
/// WHAT IT DOES:
/// - Draws a ring that fills from 0 to `progress` (0..1) with animated entry.
/// - Shows the percentage as bold text centered in the ring.
/// - Uses the AngularGradient (accentColor → its 70% opacity) for the fill arc.
/// - Updates smoothly on progress changes via onChange modifier.
///
/// WHEN IT SHOWS:
/// - Currently unused directly in any view, but available for dashboard
///   stat visualizations (e.g., daily goal, quiz score).
///
/// HOW IT WORKS:
/// - Two Circles stacked: a background track (12% opacity accent) and a trim arc.
/// - animatedProgress @State starts at 0, animates to `progress` on appear (0.8s easeOut).
/// - onChange of progress triggers a 0.6s easeOut animation to the new value.
struct ProgressRing: View {
    @EnvironmentObject private var theme: ThemeManager
    var progress: Double // 0..1
    var size: CGFloat = 88

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.accentColor.opacity(0.12), lineWidth: 10)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundStyle(AngularGradient(gradient: Gradient(colors: [theme.accentColor, theme.accentColor.opacity(0.7)]), center: .center))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .bold))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newProgress
            }
        }
    }
}

struct ProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        ProgressRing(progress: 0.72)
            .environmentObject(ThemeManager())
            .padding()
    }
}
