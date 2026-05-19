import SwiftUI

struct GamificationInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeAccentColor) private var accentColor
    @State private var showBadges = false

    private let badgeColumns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    private let badgePreviews: [BadgePreview] = [
        BadgePreview(
            title: "Early Bird",
            detail: "Complete a lesson before 8:00 AM.",
            systemImage: "sun.max.fill"
        ),
        BadgePreview(
            title: "Word Smith",
            detail: "Save 50 vocabulary words in total.",
            systemImage: "textformat.abc"
        ),
        BadgePreview(
            title: "Consistent Learner",
            detail: "Achieve a 7-day milestone streak.",
            systemImage: "flame.fill"
        )
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                streakBlock
                xpBlock
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
        .onAppear {
            showBadges = false

            DispatchQueue.main.async {
                withAnimation(EngifySpring.cascade) {
                    showBadges = true
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Progress & Rewards")
                .font(EngifyTypography.cardTitle)
                .foregroundStyle(EngifyColors.textPrimary)

            Text("See how streaks, XP, stars, and milestone badges work so you always know what moves your learning forward.")
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
        EngifyCard(tint: EngifyColors.warning) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                infoHeader(
                    systemImage: "star.fill",
                    title: "Experience Points (XP) & Stars",
                    tint: EngifyColors.warning
                )

                infoRow(
                    title: "What it is",
                    body: "Stars are your redeemable points currency, while XP measures your lifelong learning progression and levels up your main tracker bar automatically."
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("How to achieve")
                        .font(EngifyTypography.caption.weight(.semibold))
                        .foregroundStyle(EngifyColors.textSecondary)

                    rewardRow(value: "+5 XP / Stars", detail: "Save a new vocabulary word to your deck.")
                    rewardRow(value: "+15 XP / Stars", detail: "Complete a full News Article reading brief.")
                    rewardRow(value: "+20 XP / Stars", detail: "Execute a Quick Practice Sprint perfectly.")
                }
            }
        }
    }

    private var badgesBlock: some View {
        EngifyCard(tint: EngifyColors.sage) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                infoHeader(
                    systemImage: "rosette",
                    title: "Achievements & Badges",
                    tint: EngifyColors.sage
                )

                Text("Special milestone rewards unlock as your habits become more consistent.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: badgeColumns, spacing: Spacing.md) {
                    ForEach(Array(badgePreviews.enumerated()), id: \.element.id) { index, badge in
                        LockedBadgePreview(
                            badge: badge,
                            accentColor: accentColor,
                            isVisible: showBadges,
                            index: index
                        )
                    }
                }
            }
        }
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

private struct BadgePreview: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
}

private struct LockedBadgePreview: View {
    let badge: BadgePreview
    let accentColor: Color
    let isVisible: Bool
    let index: Int

    private let iconHeight: CGFloat = 94
    private let titleHeight: CGFloat = 34
    private let detailHeight: CGFloat = 54

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.sm) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(accentColor.opacity(0.08))
                    .frame(height: iconHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.clear)
                    .frame(height: iconHeight)
                    .overlay(
                        Image(systemName: badge.systemImage)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(accentColor.opacity(0.45))
                    )

                Image(systemName: "lock.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(EngifyColors.textInverse)
                    .padding(6)
                    .background(accentColor, in: Circle())
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
