import SwiftUI

// MARK: - Progress Bar

struct ProgressBar: View {
    private struct ProgressDisplayState: Equatable {
        let level: Int
        let currentXP: Int
        let totalLevelXP: Int

        init(level: Int, currentXP: Int, totalLevelXP: Int) {
            self.level = level
            self.currentXP = max(0, currentXP)
            self.totalLevelXP = max(1, totalLevelXP)
        }

        init(snapshot: UserProgress.XPSnapshot) {
            self.init(
                level: snapshot.level,
                currentXP: snapshot.xpIntoCurrentLevel,
                totalLevelXP: snapshot.xpNeededForLevel
            )
        }

        var progressFraction: CGFloat {
            min(max(CGFloat(currentXP) / CGFloat(totalLevelXP), 0), 1)
        }
    }

    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.themeAccentColor) private var accentColor
    @State private var animatedState = ProgressDisplayState(snapshot: UserProgress.initial.snapshot)
    @State private var animatedTotalXP = 0
    @State private var xpAnimationTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: Spacing.md) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(EngifyColors.border.opacity(0.82))
                            .frame(height: 12)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: authManager.isGuestMode
                                        ? [EngifyColors.textSecondary.opacity(0.22), EngifyColors.textSecondary.opacity(0.14)]
                                        : [accentColor, accentColor.opacity(0.72)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * displayedProgress,
                                height: 12
                            )
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 12)

                Text("Lv \(displayedLevel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EngifyColors.textSecondary)
                    .lineLimit(1)
            }

            Text(progressFractionText)
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundStyle(Color(red: 0.29, green: 0.29, blue: 0.33))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            syncProgressDisplayToCurrentState()
        }
        .onChange(of: gamification.progress.xp) { newXP in
            guard !authManager.isGuestMode else { return }
            animateXPProgress(to: newXP)
        }
        .onChange(of: authManager.isGuestMode) { _ in
            syncProgressDisplayToCurrentState()
        }
        .onDisappear {
            xpAnimationTask?.cancel()
        }
    }

    private var displayedProgress: CGFloat {
        if authManager.isGuestMode {
            return 0.25
        }

        return animatedState.progressFraction
    }

    private var displayedLevel: Int {
        authManager.isGuestMode ? 10 : animatedState.level
    }

    private var progressFractionText: String {
        let currentXP = authManager.isGuestMode ? 1 : animatedState.currentXP
        let totalLevelXP = authManager.isGuestMode ? 4 : animatedState.totalLevelXP
        return "\(currentXP)/\(totalLevelXP)"
    }

    private func syncProgressDisplayToCurrentState() {
        xpAnimationTask?.cancel()

        if authManager.isGuestMode {
            animatedState = ProgressDisplayState(level: 10, currentXP: 1, totalLevelXP: 4)
            animatedTotalXP = 0
            return
        }

        let snapshot = gamification.progress.snapshot
        animatedState = ProgressDisplayState(snapshot: snapshot)
        animatedTotalXP = snapshot.totalXP
    }

    private func animateXPProgress(to totalXP: Int) {
        xpAnimationTask?.cancel()

        let startXP = animatedTotalXP
        let targetXP = max(0, totalXP)

        guard targetXP != startXP else {
            let snapshot = UserProgress.snapshot(forTotalXP: targetXP)
            animatedState = ProgressDisplayState(snapshot: snapshot)
            animatedTotalXP = targetXP
            return
        }

        xpAnimationTask = Task {
            if targetXP < startXP {
                let snapshot = UserProgress.snapshot(forTotalXP: targetXP)
                await MainActor.run {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0)) {
                        animatedState = ProgressDisplayState(snapshot: snapshot)
                    }
                    animatedTotalXP = targetXP
                }
                return
            }

            let states = progressStatesForXPTransition(from: startXP, to: targetXP)

            for transition in states {
                if Task.isCancelled { return }

                await MainActor.run {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0)) {
                        animatedState = transition.state
                    }
                    animatedTotalXP = transition.resolvedXP
                }

                try? await Task.sleep(nanoseconds: transition.delayNanoseconds)
            }

            if Task.isCancelled { return }

            let finalSnapshot = UserProgress.snapshot(forTotalXP: targetXP)
            await MainActor.run {
                animatedState = ProgressDisplayState(snapshot: finalSnapshot)
                animatedTotalXP = targetXP
            }
        }
    }

    private func progressStatesForXPTransition(from startXP: Int, to targetXP: Int) -> [(state: ProgressDisplayState, resolvedXP: Int, delayNanoseconds: UInt64)] {
        guard targetXP > startXP else { return [] }

        var transitions: [(state: ProgressDisplayState, resolvedXP: Int, delayNanoseconds: UInt64)] = []

        for nextXPValue in (startXP + 1)...targetXP {
            let previousSnapshot = UserProgress.snapshot(forTotalXP: nextXPValue - 1)
            let nextLevelThreshold = previousSnapshot.xpForCurrentLevelStart + previousSnapshot.xpNeededForLevel

            if nextXPValue == nextLevelThreshold {
                let cappedState = ProgressDisplayState(
                    level: previousSnapshot.level,
                    currentXP: previousSnapshot.xpNeededForLevel,
                    totalLevelXP: previousSnapshot.xpNeededForLevel
                )
                transitions.append((cappedState, nextXPValue, 160_000_000))
            }

            let snapshot = UserProgress.snapshot(forTotalXP: nextXPValue)
            let steppedState = ProgressDisplayState(snapshot: snapshot)
            let delay: UInt64 = nextXPValue == targetXP ? 0 : 55_000_000
            transitions.append((steppedState, nextXPValue, delay))
        }

        return transitions
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

            Text("\(isLocked ? 1 : max(1, streakDays))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 38)
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
        let displayedCount = isLocked ? 5 : max(0, count)

        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(isLocked ? EngifyColors.textSecondary.opacity(0.55) : accentColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: isLocked ? "lock.fill" : "star.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(EngifyColors.textInverse)
                )

            Text("\(displayedCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 38)
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
    @Environment(\.themeAccentColor) private var accentColor
    let amount: Int
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor)

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
    @Environment(\.themeAccentColor) private var accentColor
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
                            .foregroundStyle(accentColor)
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
    enum Style {
        case standard
        case levelUp
    }

    @Environment(\.themeAccentColor) private var accentColor
    let isActive: Bool
    var style: Style = .standard
    var particleCount: Int = 20
    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let progress = Double(animationProgress)
                for particle in particles {
                    var copy = context
                    let currentOpacity = max(0, particle.opacity * (1 - progress))
                    copy.opacity = currentOpacity
                    let currentX = particle.x + (particle.drift * progress)
                    let currentY = particle.y + (particle.fallDistance * progress)
                    let currentRotation = particle.rotation + (particle.spin * progress)
                    let currentScale = particle.scale * (1 - progress * 0.18)
                    let rect = CGRect(
                        x: currentX - particle.size / 2,
                        y: currentY - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    let path = confettiPath(for: particle, in: rect)
                    copy.translateBy(x: currentX, y: currentY)
                    copy.rotate(by: .degrees(currentRotation))
                    copy.translateBy(x: -currentX, y: -currentY)
                    copy.scaleBy(x: currentScale, y: currentScale)
                    copy.fill(path, with: .color(particle.color))
                }
            }
            .onAppear {
                if isActive {
                    spawnParticles(width: geo.size.width, height: geo.size.height)
                }
            }
            .onChange(of: isActive) { isNowActive in
                if isNowActive {
                    spawnParticles(width: geo.size.width, height: geo.size.height)
                }
            }
        }
    }

    private func spawnParticles(width: CGFloat, height: CGFloat) {
        let colors: [Color] = [accentColor, EngifyColors.sky, EngifyColors.sage, EngifyColors.coral]
        let burst = styleMetrics
        animationProgress = 0
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...max(width, 100)),
                y: CGFloat.random(in: burst.spawnYRange(for: height)),
                color: colors.randomElement() ?? accentColor,
                opacity: Double.random(in: 0.88...1.0),
                size: CGFloat.random(in: burst.sizeRange),
                rotation: Double.random(in: 0...360),
                spin: Double.random(in: burst.spinRange),
                drift: CGFloat.random(in: burst.driftRange),
                fallDistance: CGFloat.random(in: burst.fallDistanceRange),
                scale: CGFloat.random(in: burst.scaleRange),
                shape: ConfettiShape.allCases.randomElement() ?? .rectangle
            )
        }

        withAnimation(.easeOut(duration: burst.duration)) {
            animationProgress = 1
        }
    }

    private var styleMetrics: CelebrationBurstMetrics {
        switch style {
        case .standard:
            return CelebrationBurstMetrics(
                sizeRange: 8...16,
                spinRange: -220...220,
                driftRange: -90...90,
                fallDistanceRange: 220...380,
                scaleRange: 0.86...1.12,
                duration: 1.45,
                spawnBaseY: -80,
                spawnHeightFactor: 0.12,
                spawnHeightMinimum: 60
            )
        case .levelUp:
            return CelebrationBurstMetrics(
                sizeRange: 10...20,
                spinRange: -320...320,
                driftRange: -150...150,
                fallDistanceRange: 280...460,
                scaleRange: 0.92...1.22,
                duration: 1.8,
                spawnBaseY: -120,
                spawnHeightFactor: 0.18,
                spawnHeightMinimum: 90
            )
        }
    }

    private func confettiPath(for particle: ConfettiParticle, in rect: CGRect) -> Path {
        switch particle.shape {
        case .rectangle:
            return Path(roundedRect: rect, cornerRadius: rect.width * 0.22)
        case .circle:
            return Path(ellipseIn: rect)
        case .streamer:
            return Path(
                roundedRect: CGRect(
                    x: rect.minX,
                    y: rect.midY - rect.height * 0.18,
                    width: rect.width,
                    height: rect.height * 0.36
                ),
                cornerRadius: rect.height * 0.18
            )
        }
    }
}

private enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case streamer
}

private struct CelebrationBurstMetrics {
    let sizeRange: ClosedRange<CGFloat>
    let spinRange: ClosedRange<Double>
    let driftRange: ClosedRange<CGFloat>
    let fallDistanceRange: ClosedRange<CGFloat>
    let scaleRange: ClosedRange<CGFloat>
    let duration: Double
    let spawnBaseY: CGFloat
    let spawnHeightFactor: CGFloat
    let spawnHeightMinimum: CGFloat

    func spawnYRange(for height: CGFloat) -> ClosedRange<CGFloat> {
        spawnBaseY...max(height * spawnHeightFactor, spawnHeightMinimum)
    }
}

private struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var opacity: Double
    var size: CGFloat
    var rotation: Double
    var spin: Double
    var drift: CGFloat
    var fallDistance: CGFloat
    var scale: CGFloat
    var shape: ConfettiShape
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

struct LevelUpOverlay: View {
    @EnvironmentObject private var gamification: GamificationManager

    var body: some View {
        if gamification.showLevelUp {
            levelUpContent
            .overlay {
                CelebrationView(
                    isActive: true,
                    style: .levelUp,
                    particleCount: gamification.lastLevelUpWasMilestone ? 42 : 20
                )
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var levelUpContent: some View {
        let unlockedLevel = gamification.lastUnlockedLevel ?? gamification.progress.resolvedLevel

        if gamification.lastLevelUpWasMilestone {
            MilestoneLevelUpCard(
                level: unlockedLevel,
                message: LevelCongratulationLibrary.message(for: unlockedLevel)
            ) {
                dismissLevelUp()
            }
        } else {
            CompletionView(
                title: "Congratulations!",
                message: LevelCongratulationLibrary.message(for: unlockedLevel),
                pointsEarned: 0
            ) {
                dismissLevelUp()
            }
        }
    }

    private func dismissLevelUp() {
        gamification.lastUnlockedLevel = nil
        gamification.lastLevelUpWasMilestone = false
        gamification.showLevelUp = false
    }
}

struct BadgeUnlockedOverlay: View {
    @EnvironmentObject private var gamification: GamificationManager

    var body: some View {
        if gamification.showBadgeUnlocked, let badge = gamification.latestUnlockedBadge {
            BadgeUnlockedPopup(badge: badge) {
                gamification.dismissBadgeUnlocked()
            }
            .overlay {
                CelebrationView(isActive: true, style: .levelUp, particleCount: 28)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct BadgeUnlockedPopup: View {
    @Environment(\.themeAccentColor) private var accentColor
    let badge: AchievementBadge
    let onDismiss: () -> Void
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(spacing: Spacing.cardGap) {
                EngifyIconBadge(systemImage: badge.systemImage, tint: accentColor, size: 82)
                    .scaleEffect(showContent ? 1 : 0.82)

                VStack(spacing: Spacing.xs) {
                    Text("Badge Unlocked!")
                        .font(EngifyTypography.screenTitle)
                        .foregroundStyle(EngifyColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(badge.title)
                        .font(EngifyTypography.cardTitle)
                        .foregroundStyle(accentColor)

                    Text(badge.detail)
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                CompletionButton(title: "Awesome", systemImage: "sparkles", action: onDismiss)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: 360)
            .background(EngifyColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
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

private struct MilestoneLevelUpCard: View {
    @Environment(\.themeAccentColor) private var accentColor
    let level: Int
    let message: String
    let onContinue: () -> Void
    @State private var showContent = false

    private var isMaxLevel: Bool {
        level >= 100
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.26)
                .ignoresSafeArea()

            VStack(spacing: Spacing.cardGap) {
                EngifyIconBadge(systemImage: "crown.fill", tint: EngifyColors.warning, size: 92)
                    .scaleEffect(showContent ? 1 : 0.82)

                VStack(spacing: Spacing.sm) {
                    Text("Big Congratulations!")
                        .font(EngifyTypography.screenTitle)
                        .foregroundStyle(EngifyColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(isMaxLevel ? "You reached Level MAX" : "You reached Level \(level)")
                        .font(EngifyTypography.cardTitle)
                        .foregroundStyle(accentColor)

                    Text(message)
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: Spacing.sm) {
                    milestonePill(text: isMaxLevel ? "MAX" : "Milestone")
                    milestonePill(text: isMaxLevel ? "Level 100" : "Lv \(level)")
                }

                CompletionButton(
                    title: isMaxLevel ? "Celebrate MAX" : "Keep Going",
                    systemImage: "sparkles",
                    action: onContinue
                )
            }
            .padding(Spacing.xl)
            .frame(maxWidth: 388)
            .background(EngifyColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 32, x: 0, y: 16)
            .padding(.horizontal, Spacing.screenPadding)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.92)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
                showContent = true
            }
        }
    }

    private func milestonePill(text: String) -> some View {
        Text(text)
            .font(EngifyTypography.caption.weight(.semibold))
            .foregroundStyle(EngifyColors.textInverse)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [EngifyColors.warning, accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }
}

private enum LevelCongratulationLibrary {
    private static let messages: [String] = [
        "Level 1 begins your Engify journey. Every strong learner starts with one brave step.",
        "Level 2 already looks good on you. You are building a real learning rhythm.",
        "Level 3 means your effort is starting to stack into momentum.",
        "Level 4 shows you are not just curious, you are committed.",
        "Level 5 is a real milestone. Your consistency is becoming part of who you are.",
        "Level 6 proves your daily practice is turning into habit.",
        "Level 7 shows your focus is getting sharper with every session.",
        "Level 8 means your progress is becoming easier to feel and see.",
        "Level 9 is a strong sign that you keep showing up for yourself.",
        "Level 10 is a major win. You have built a foundation worth being proud of.",
        "Level 11 shows you are moving beyond the beginner mindset.",
        "Level 12 means your learning engine is warming up beautifully.",
        "Level 13 proves you can keep growing even after the early excitement.",
        "Level 14 shows your patience is paying off in steady gains.",
        "Level 15 is a strong checkpoint. You are learning with real intention now.",
        "Level 16 means your English journey is getting stronger day by day.",
        "Level 17 shows your discipline is becoming visible in the results.",
        "Level 18 proves small sessions really can create big change.",
        "Level 19 means you are carrying momentum with confidence.",
        "Level 20 is a huge milestone. You are no longer starting, you are progressing.",
        "Level 21 shows your consistency can carry you far beyond quick motivation.",
        "Level 22 means your study habit is becoming dependable.",
        "Level 23 proves your effort still rises even when the path gets longer.",
        "Level 24 shows you are turning repetition into mastery.",
        "Level 25 is a proud milestone. Your growth is becoming undeniable.",
        "Level 26 means your routine is doing real work for you.",
        "Level 27 shows the learner in you is getting stronger every week.",
        "Level 28 proves progress loves patience and you are giving it both.",
        "Level 29 means you are staying in the game with real endurance.",
        "Level 30 is an impressive achievement. You have built meaningful momentum.",
        "Level 31 shows your confidence is starting to match your effort.",
        "Level 32 means your persistence is becoming a superpower.",
        "Level 33 proves you can keep climbing without losing focus.",
        "Level 34 shows your learning curve is still moving upward.",
        "Level 35 is a standout milestone. You are developing real long-term strength.",
        "Level 36 means you are training your future fluency one step at a time.",
        "Level 37 shows your work ethic is becoming part of your identity.",
        "Level 38 proves your progress is powered by consistency, not luck.",
        "Level 39 means you are staying steady when many people would slow down.",
        "Level 40 is a big achievement. You have built durable momentum.",
        "Level 41 shows you are growing with maturity and patience.",
        "Level 42 means your learning rhythm is becoming natural.",
        "Level 43 proves your dedication keeps opening new doors.",
        "Level 44 shows your progress is deepening, not just continuing.",
        "Level 45 is a major checkpoint. You are clearly serious about growth.",
        "Level 46 means your practice is becoming polished and purposeful.",
        "Level 47 shows your commitment is stronger than temporary obstacles.",
        "Level 48 proves you know how to keep moving forward.",
        "Level 49 means you are one step away from a huge milestone.",
        "Level 50 is enormous. Halfway to 100, and every level here is earned.",
        "Level 51 shows your journey has real staying power.",
        "Level 52 means your consistency is carrying you into elite territory.",
        "Level 53 proves you can keep rising without losing your spark.",
        "Level 54 shows your effort is as steady as ever.",
        "Level 55 is a powerful milestone. You are growing into an advanced learner mindset.",
        "Level 56 means your habits are doing exactly what great habits should do.",
        "Level 57 shows your discipline keeps paying off.",
        "Level 58 proves you are stronger than the slow days.",
        "Level 59 means you are closing in on another impressive stretch.",
        "Level 60 is a remarkable achievement. Your persistence is shaping something big.",
        "Level 61 shows you know how to keep the long game alive.",
        "Level 62 means your consistency is now part of your advantage.",
        "Level 63 proves your learning journey has real depth.",
        "Level 64 shows how far steady progress can take you.",
        "Level 65 is a proud milestone. You are building mastery brick by brick.",
        "Level 66 means your focus is helping everything click together.",
        "Level 67 shows you are still climbing with purpose.",
        "Level 68 proves you have turned effort into identity.",
        "Level 69 means your momentum is calm, strong, and reliable.",
        "Level 70 is a serious achievement. You are setting a high bar for yourself.",
        "Level 71 shows your resilience keeps your progress alive.",
        "Level 72 means your growth is becoming hard to ignore.",
        "Level 73 proves your habits are built to last.",
        "Level 74 shows you can keep improving without needing shortcuts.",
        "Level 75 is a huge milestone. Three quarters of the way to 100 is incredible work.",
        "Level 76 means your commitment is carrying you into rare territory.",
        "Level 77 shows your progress is grounded in real discipline.",
        "Level 78 proves that steady effort keeps winning.",
        "Level 79 means you are almost at another unforgettable checkpoint.",
        "Level 80 is outstanding. Your consistency has become something special.",
        "Level 81 shows your learning strength is still growing.",
        "Level 82 means you are building excellence through repetition.",
        "Level 83 proves your long-term mindset is working.",
        "Level 84 shows your practice has real staying power.",
        "Level 85 is a major milestone. You are pushing well beyond ordinary persistence.",
        "Level 86 means your habits are now carrying serious momentum.",
        "Level 87 shows your dedication keeps opening bigger possibilities.",
        "Level 88 proves you are trusted by your own consistency.",
        "Level 89 means the path to 100 is getting very real.",
        "Level 90 is extraordinary. You have turned persistence into progress at scale.",
        "Level 91 shows your finish-line focus is getting stronger.",
        "Level 92 means your effort is still fresh and effective.",
        "Level 93 proves you can keep climbing even at high levels.",
        "Level 94 shows your growth mindset is doing its job.",
        "Level 95 is an elite milestone. You are incredibly close to triple digits.",
        "Level 96 means your dedication is carrying you through the final stretch.",
        "Level 97 shows your consistency remains powerful under pressure.",
        "Level 98 proves you are almost ready for a legendary checkpoint.",
        "Level 99 means one more step to something unforgettable.",
        "Level 100 is legendary. You built this milestone with patience, discipline, and heart."
    ]

    static func message(for level: Int) -> String {
        guard level > 0, level <= messages.count else {
            return "You reached Level \(level). Your momentum keeps getting stronger."
        }

        return messages[level - 1]
    }
}
