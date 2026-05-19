import SwiftUI

// MARK: - Progress Bar

struct ProgressBar: View {
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        HStack(spacing: Spacing.sm) {
            LevelBadge(level: authManager.isGuestMode ? 0 : gamification.progress.level, isLocked: authManager.isGuestMode)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(EngifyColors.border.opacity(0.7))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: authManager.isGuestMode
                                    ? [EngifyColors.textSecondary.opacity(0.28), EngifyColors.textSecondary.opacity(0.18)]
                                    : [accentColor, accentColor.opacity(0.72)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(12, geometry.size.width * (authManager.isGuestMode ? 0.04 : gamification.progress.levelProgress)),
                            height: 10
                        )
                }
            }
            .frame(height: 10)

            Text(authManager.isGuestMode ? "Lv 0" : "Lv \(gamification.progress.level)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LevelBadge: View {
    let level: Int
    var isLocked = false
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        Circle()
            .fill(isLocked ? EngifyColors.textSecondary.opacity(0.55) : accentColor)
            .frame(width: 34, height: 34)
            .overlay(
                Group {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(EngifyColors.textInverse)
                    } else {
                        Text("\(level)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(EngifyColors.textInverse)
                    }
                }
            )
    }
}

struct StreakCounter: View {
    let streakDays: Int
    var isLocked = false
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isLocked ? EngifyColors.textSecondary : (streakDays > 0 ? accentColor : EngifyColors.textSecondary))

            Text("\(isLocked ? 0 : streakDays)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 36)
        .background(EngifyColors.surface)
        .overlay(
            Capsule()
                .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct PointsCounter: View {
    let count: Int
    var isLocked = false
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(isLocked ? EngifyColors.textSecondary.opacity(0.55) : accentColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: isLocked ? "lock.fill" : "star.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(EngifyColors.textInverse)
                )

            Text("\(isLocked ? 0 : count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 36)
        .background(EngifyColors.surface)
        .overlay(
            Capsule()
                .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Buttons / Feedback

struct SolidButtonStyle: ButtonStyle {
    @Environment(\.themeAccentColor) private var accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EngifyTypography.bodyStrong)
            .foregroundStyle(EngifyColors.textInverse)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, Spacing.lg)
            .background(
                LinearGradient(
                    colors: [
                        accentColor.opacity(configuration.isPressed ? 0.88 : 1),
                        accentColor.opacity(configuration.isPressed ? 0.72 : 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(configuration.isPressed ? EngifySpring.tapDown : EngifySpring.jellyRelease, value: configuration.isPressed)
            .compositingGroup()
            .drawingGroup()
    }
}

struct CompletionButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        PrimaryButton(
            title: title,
            systemImage: systemImage,
            action: action,
            isDisabled: isDisabled
        )
    }
}

struct ScoreToast: View {
    let amount: Int
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(EngifyColors.accent)

            Text("+\(amount)")
                .font(.caption.weight(.bold))
                .foregroundStyle(EngifyColors.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(EngifyColors.surface)
        .overlay(
            Capsule()
                .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: EngifyColors.primary.opacity(0.08), radius: 10, x: 0, y: 6)
        .scaleEffect(isVisible ? 1 : 0.86)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
            }
        }
    }
}

typealias XPGainToast = ScoreToast

// MARK: - Completion View

struct CompletionView: View {
    let title: String
    let message: String
    let pointsEarned: Int
    let onContinue: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(spacing: Spacing.cardGap) {
                EngifyIconBadge(systemImage: "checkmark.seal.fill", tint: EngifyColors.sage, size: 72)
                    .scaleEffect(showContent ? 1 : 0.84)

                VStack(spacing: Spacing.xs) {
                    Text(title)
                        .font(EngifyTypography.cardTitle)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(message)
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if pointsEarned > 0 {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(EngifyColors.accent)
                        Text("+\(pointsEarned) XP")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(EngifyColors.textPrimary)
                    }
                }

                CompletionButton(title: "Continue", systemImage: "arrow.right", action: onContinue)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: 360)
            .background(EngifyColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 14)
            .padding(.horizontal, Spacing.screenPadding)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.94)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.76)) {
                showContent = true
            }
        }
    }
}

// MARK: - Celebration View

struct CelebrationView: View {
    let isActive: Bool
    @State private var dots: [DotParticle] = []

    var body: some View {
        Canvas { context, _ in
            for dot in dots {
                var copy = context
                copy.opacity = dot.opacity
                copy.fill(
                    Path(ellipseIn: CGRect(x: dot.x - 4, y: dot.y - 4, width: 8, height: 8)),
                    with: .color(dot.color)
                )
            }
        }
        .onAppear {
            if isActive {
                spawnDots()
            }
        }
        .onChange(of: isActive) { isNowActive in
            if isNowActive {
                spawnDots()
            }
        }
    }

    private func spawnDots() {
        let colors: [Color] = [EngifyColors.accent, EngifyColors.sky, EngifyColors.sage, EngifyColors.coral]
        dots = (0..<20).map { _ in
            DotParticle(
                x: CGFloat.random(in: 0...400),
                y: CGFloat.random(in: -50...100),
                color: colors.randomElement() ?? EngifyColors.accent,
                opacity: 1
            )
        }

        for index in dots.indices {
            withAnimation(.easeOut(duration: 1.2)) {
                dots[index].y += 300
                dots[index].opacity = 0
            }
        }
    }
}

struct DotParticle {
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Overlay

struct LessonCompleteOverlay: View {
    @EnvironmentObject private var gamification: GamificationManager

    var body: some View {
        if let result = gamification.currentLessonResult {
            CompletionView(
                title: "Lesson Complete",
                message: lessonMessage(for: result.lessonType),
                pointsEarned: result.xpEarned
            ) {
                gamification.dismissLessonComplete()
            }
            .overlay {
                CelebrationView(isActive: true)
                    .allowsHitTesting(false)
            }
        }
    }

    private func lessonMessage(for lessonType: LessonType) -> String {
        switch lessonType {
        case .vocabulary:
            return "You expanded your vocabulary and kept your streak moving."
        case .practice:
            return "Strong work. Your practice session turned effort into progress."
        case .dictionary:
            return "You explored new word meanings and sharpened understanding."
        case .news:
            return "You learned from real reading and built stronger comprehension."
        }
    }
}
