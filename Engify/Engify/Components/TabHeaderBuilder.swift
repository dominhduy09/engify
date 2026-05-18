import SwiftUI

struct TabHeaderBuilder {
    static func buildTabHeader(
        icon: String,
        title: String,
        subtitle: String,
        primaryColor: Color,
        secondaryColor: Color
    ) -> some View {
        EngifyCard(tint: primaryColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: primaryColor.opacity(0.24), radius: 12, x: 0, y: 8)

                        Image(systemName: icon)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(EngifyColors.textInverse)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(title)
                            .font(EngifyTypography.screenTitle)
                            .foregroundStyle(EngifyColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(subtitle)
                            .font(EngifyTypography.body)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                LinearGradient(
                    colors: [primaryColor.opacity(0.32), secondaryColor.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
        }
    }
}

enum TabHeaderConfig {
    static let vocabulary = (
        icon: "book.circle.fill",
        title: "Daily Vocabulary",
        subtitle: "Expand your English words",
        primaryColor: EngifyColors.accent,
        secondaryColor: EngifyColors.sky
    )

    static let dictionary = (
        icon: "text.magnifyingglass",
        title: "Dictionary",
        subtitle: "Discover word meanings",
        primaryColor: EngifyColors.accent,
        secondaryColor: EngifyColors.sky
    )

    static let news = (
        icon: "newspaper.fill",
        title: "News & Reading",
        subtitle: "Learn while reading real stories",
        primaryColor: EngifyColors.accent,
        secondaryColor: EngifyColors.sky
    )

    static let practice = (
        icon: "target",
        title: "Practice",
        subtitle: "Build confidence with active exercises",
        primaryColor: EngifyColors.accent,
        secondaryColor: EngifyColors.sage
    )
}

extension View {
    func tabTransition() -> some View {
        transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
    }
}
