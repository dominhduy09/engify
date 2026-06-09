import SwiftUI

struct GamificationInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeAccentColor) private var accentColor
    @EnvironmentObject private var gamification: GamificationManager
    @State private var showBadges = false

    private let badgeColumns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    private let milestoneColumns = [
        GridItem(.adaptive(minimum: 94), spacing: Spacing.sm)
    ]

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    streakBlock
                    xpBlock
                    pointsBlock
                    milestoneLevelsBlock
                    badgesBlock

                    Button("Back to Learning") {
                        dismiss()
                    }
                    .buttonStyle(SolidButtonStyle())
                    .padding(.top, Spacing.sm)
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            .background(sheetBackground.ignoresSafeArea())
            .navigationTitle("Progress & Rewards")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            showBadges = false

            DispatchQueue.main.async {
                withAnimation(EngifySpring.cascade) {
                    showBadges = true
                }
            }
        }
    }

    private var streakBlock: some View {
        EngifyCard(tint: accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                infoHeader(
                    systemImage: "flame.fill",
                    title: "Daily Streak",
                    tint: accentColor
                )

                infoRow(
                    title: "What it is",
                    body: "Tracks how many consecutive days you have opened the app and completed at least one activity like Vocabulary lookup, News reading, or a Practice workout."
                )

                infoRow(
                    title: "How to achieve",
                    body: "Complete any task before midnight every day to keep the flame burning. Missing a day resets the counter to zero."
                )
            }
        }
    }

    private var xpBlock: some View {
        EngifyCard(tint: accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                infoHeader(
                    systemImage: "bolt.fill",
                    title: "Experience Points (XP)",
                    tint: accentColor
                )

                infoRow(
                    title: "What it is",
                    body: "XP measures your learning progress. As your XP grows, the progress bar fills and your level increases automatically."
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("How to achieve")
                        .font(EngifyTypography.caption.weight(.semibold))
                        .foregroundStyle(EngifyColors.textSecondary)

                    rewardRow(value: "+5 XP", detail: "Save a new vocabulary word to your deck.")
                    rewardRow(value: "+15 XP", detail: "Complete a full News Article reading brief.")
                    rewardRow(value: "+20 XP", detail: "Execute a Quick Practice Sprint perfectly.")
                }
            }
        }
    }

    private var pointsBlock: some View {
        EngifyCard(tint: accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                infoHeader(
                    systemImage: "star.fill",
                    title: "Points",
                    tint: accentColor
                )

                infoRow(
                    title: "What it is",
                    body: "Points are your reward currency. You earn them by completing learning activities and building steady study habits."
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("How to achieve")
                        .font(EngifyTypography.caption.weight(.semibold))
                        .foregroundStyle(EngifyColors.textSecondary)

                    rewardRow(value: "+5 Points", detail: "Save a new vocabulary word to your deck.")
                    rewardRow(value: "+15 Points", detail: "Complete a full News Article reading brief.")
                    rewardRow(value: "+20 Points", detail: "Execute a Quick Practice Sprint perfectly.")
                }
            }
        }
    }

    private var milestoneLevelsBlock: some View {
        EngifyCard(tint: accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                infoHeader(
                    systemImage: "flag.checkered.2.crossed",
                    title: "Level Milestones",
                    tint: accentColor
                )

                Text("Big congratulations appear at level 2, level 5, and every 10 levels after that until Level MAX.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: milestoneColumns, spacing: Spacing.sm) {
                    ForEach(levelMilestones, id: \.self) { level in
                        milestoneLevelChip(level: level)
                    }
                }
            }
        }
    }

    private var badgesBlock: some View {
        EngifyCard(tint: accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                infoHeader(
                    systemImage: "rosette",
                    title: "Achievements & Badges",
                    tint: accentColor
                )

                Text("Special milestone rewards unlock as your habits become more consistent.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: badgeColumns, spacing: Spacing.md) {
                    ForEach(Array(AchievementBadge.allCases.enumerated()), id: \.element.id) { index, badge in
                        AchievementBadgePreview(
                            badge: badge,
                            accentColor: accentColor,
                            isUnlocked: gamification.isBadgeUnlocked(badge),
                            isVisible: showBadges,
                            index: index
                        )
                    }
                }
            }
        }
    }

    private var levelMilestones: [Int] {
        [2, 5] + Array(stride(from: 10, through: 100, by: 10))
    }

    private func milestoneLevelChip(level: Int) -> some View {
        let currentLevel = gamification.progress.resolvedLevel
        let isReached = currentLevel >= level
        let isCurrent = currentLevel == level
        let isMaxLevel = level == 100
        let tint = isReached ? (isMaxLevel ? EngifyColors.warning : accentColor) : EngifyColors.textSecondary

        return VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: isReached ? "checkmark.seal.fill" : "lock.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isReached ? tint : EngifyColors.textSecondary)

                Text(isMaxLevel ? "MAX" : "Lv \(level)")
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(EngifyColors.textPrimary)
            }

            Text(isCurrent ? "Current" : (isReached ? "Reached" : "Upcoming"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(isReached ? tint : EngifyColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isReached ? tint.opacity(0.10) : EngifyColors.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isReached ? tint.opacity(0.22) : EngifyColors.border.opacity(0.7), lineWidth: 1)
        )
    }

    private var sheetBackground: LinearGradient {
        LinearGradient(
            colors: [EngifyColors.surface, EngifyColors.canvas],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func infoHeader(systemImage: String, title: String, tint: Color) -> some View {
        HStack(spacing: Spacing.md) {
            EngifyIconBadge(systemImage: systemImage, tint: tint, size: 44)

            Text(title)
                .font(EngifyTypography.headline)
                .foregroundStyle(EngifyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func infoRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(EngifyTypography.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textSecondary)

            Text(body)
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rewardRow(value: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Circle()
                .fill(accentColor.opacity(0.16))
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(value)
                    .font(EngifyTypography.bodyStrong)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text(detail)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AchievementBadgePreview: View {
    let badge: AchievementBadge
    let accentColor: Color
    let isUnlocked: Bool
    let isVisible: Bool
    let index: Int

    private let iconHeight: CGFloat = 94
    private let titleHeight: CGFloat = 34
    private let detailHeight: CGFloat = 54

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.sm) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill((isUnlocked ? accentColor : accentColor.opacity(0.55)).opacity(isUnlocked ? 0.14 : 0.08))
                    .frame(height: iconHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke((isUnlocked ? accentColor.opacity(0.24) : EngifyColors.border.opacity(0.8)), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.clear)
                    .frame(height: iconHeight)
                    .overlay(
                        Image(systemName: badge.systemImage)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(isUnlocked ? accentColor : accentColor.opacity(0.45))
                    )

                Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(EngifyColors.textInverse)
                    .padding(6)
                    .background(isUnlocked ? EngifyColors.sage : accentColor, in: Circle())
                    .offset(x: 6, y: -6)
            }

            Text(badge.title)
                .font(EngifyTypography.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: titleHeight, alignment: .top)

            Text(badge.detail)
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundStyle(EngifyColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: detailHeight, alignment: .top)

            Text(isUnlocked ? "Unlocked" : "Locked")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(isUnlocked ? EngifyColors.sage : EngifyColors.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 5)
                .background((isUnlocked ? EngifyColors.sage : EngifyColors.border).opacity(0.14))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -26)
        .scaleEffect(isVisible ? 1 : 0.92, anchor: .top)
        .animation(EngifySpring.cascade.delay(Double(index) * 0.05), value: isVisible)
        .compositingGroup()
        .drawingGroup()
    }
}
