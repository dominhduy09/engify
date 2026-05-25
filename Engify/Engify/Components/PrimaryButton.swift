import SwiftUI

enum EngifyButtonSize {
    case compact
    case regular
    case large

    var verticalPadding: CGFloat {
        switch self {
        case .compact: return 12
        case .regular: return 16
        case .large: return 18
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 16
        case .regular: return 20
        case .large: return 22
        }
    }

    var minHeight: CGFloat {
        switch self {
        case .compact: return 44
        case .regular: return 52
        case .large: return 56
        }
    }
}

enum EngifyGelSurfaceStyle {
    case primary
    case secondary
    case activePill
}

struct EngifyGelRoundedButtonSurface: View {
    let tint: Color
    let style: EngifyGelSurfaceStyle
    let isDisabled: Bool
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

            ZStack {
                shape
                    .fill(baseGradient)

                shape
                    .fill(topGlowGradient)
                    .opacity(isDisabled ? 0.45 : 1)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDisabled ? 0.16 : 0.34),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: proxy.size.width * 0.92, height: proxy.size.height * 0.72)
                    .offset(y: -proxy.size.height * 0.28)
                    .blur(radius: 1.2)

                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )

                shape
                    .strokeBorder(tint.opacity(style == .secondary ? 0.20 : 0.34), lineWidth: 2.4)
                    .blur(radius: 2.4)
                    .opacity(isDisabled ? 0.18 : 0.62)
            }
            .clipShape(shape)
        }
    }

    private var baseGradient: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [
                    tint.opacity(isDisabled ? 0.42 : 0.96),
                    tint.opacity(isDisabled ? 0.34 : 0.84),
                    tint.opacity(isDisabled ? 0.28 : 0.66)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [
                    Color.white.opacity(isDisabled ? 0.54 : 0.82),
                    tint.opacity(isDisabled ? 0.08 : 0.18),
                    tint.opacity(isDisabled ? 0.05 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .activePill:
            return LinearGradient(
                colors: [
                    tint.opacity(0.98),
                    tint.opacity(0.86),
                    tint.opacity(0.70)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var topGlowGradient: LinearGradient {
        switch style {
        case .primary, .activePill:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.34),
                    Color.white.opacity(0.12),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .secondary:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.52),
                    Color.white.opacity(0.18),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var borderColors: [Color] {
        switch style {
        case .primary:
            return [
                Color.white.opacity(0.78),
                tint.opacity(0.24),
                Color.white.opacity(0.18)
            ]
        case .secondary:
            return [
                Color.white.opacity(0.92),
                tint.opacity(0.18),
                Color.white.opacity(0.24)
            ]
        case .activePill:
            return [
                Color.white.opacity(0.80),
                tint.opacity(0.22),
                Color.white.opacity(0.16)
            ]
        }
    }
}

struct EngifyGelCapsuleSurface: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let shape = Capsule()

            ZStack {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.98),
                                tint.opacity(0.84),
                                tint.opacity(0.68)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.34),
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.32),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: proxy.size.width * 0.88, height: proxy.size.height * 0.62)
                    .offset(y: -proxy.size.height * 0.26)
                    .blur(radius: 1.1)

                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.82),
                                tint.opacity(0.24),
                                Color.white.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.05
                    )

                shape
                    .strokeBorder(tint.opacity(0.32), lineWidth: 2.4)
                    .blur(radius: 2.2)
                    .opacity(0.6)
            }
            .clipShape(shape)
        }
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String?
    var action: () -> Void
    var isDisabled: Bool = false
    var size: EngifyButtonSize = .regular
    var fillsWidth: Bool = true
    var feedbackEvent: EngifyFeedbackEvent? = nil

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            if let feedbackEvent {
                EngifyFeedback.shared.play(feedbackEvent)
            }
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }

                Text(title)
                    .font(EngifyTypography.bodyStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(EngifyColors.textInverse)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                EngifyGelRoundedButtonSurface(
                    tint: theme.accentColor,
                    style: .primary,
                    isDisabled: isDisabled,
                    cornerRadius: 18
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: shadowColor, radius: 12, x: 0, y: 8)
            .compositingGroup()
            .drawingGroup()
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .engifyJellyPress(isDisabled: isDisabled)
    }

    private var shadowColor: Color {
        isDisabled ? .clear : theme.accentColor.opacity(0.28)
    }
}

struct SecondaryButton: View {
    var title: String
    var systemImage: String?
    var action: () -> Void
    var isDisabled: Bool = false
    var size: EngifyButtonSize = .regular
    var fillsWidth: Bool = true
    var feedbackEvent: EngifyFeedbackEvent? = nil
    var tint: Color? = nil

    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            if let feedbackEvent {
                EngifyFeedback.shared.play(feedbackEvent)
            }
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }

                Text(title)
                    .font(EngifyTypography.bodyStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(isDisabled ? EngifyColors.textSecondary : resolvedTint)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                EngifyGelRoundedButtonSurface(
                    tint: resolvedTint,
                    style: .secondary,
                    isDisabled: isDisabled,
                    cornerRadius: 18
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: resolvedTint.opacity(isDisabled ? 0 : 0.12), radius: 10, x: 0, y: 6)
            .compositingGroup()
            .drawingGroup()
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .engifyJellyPress(isDisabled: isDisabled)
    }

    private var resolvedTint: Color {
        tint ?? accentColor
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.md) {
            PrimaryButton(title: "Continue", systemImage: "play.fill", action: { })
            SecondaryButton(title: "Maybe later", systemImage: "arrow.clockwise", action: { })
        }
        .environmentObject(ThemeManager())
        .padding()
    }
}
