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

struct PrimaryButton: View {
    var title: String
    var systemImage: String?
    var action: () -> Void
    var isDisabled: Bool = false
    var size: EngifyButtonSize = .regular
    var fillsWidth: Bool = true

    @EnvironmentObject private var theme: ThemeManager
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            .background(backgroundFill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.accentColor.opacity(isDisabled ? 0 : 0.16), lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: isPressed ? 6 : 12, x: 0, y: isPressed ? 4 : 8)
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
                        isPressed = false
                    }
                }
        )
    }

    private var backgroundFill: some ShapeStyle {
        if isDisabled {
            return AnyShapeStyle(theme.accentColor.opacity(0.35))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [theme.accentColor, theme.accentColor.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var shadowColor: Color {
        isDisabled ? .clear : theme.accentColor.opacity(0.24)
    }
}

struct SecondaryButton: View {
    var title: String
    var systemImage: String?
    var action: () -> Void
    var isDisabled: Bool = false
    var size: EngifyButtonSize = .regular
    var fillsWidth: Bool = true

    @Environment(\.themeAccentColor) private var accentColor
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            .foregroundStyle(isDisabled ? EngifyColors.textSecondary : accentColor)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .padding(.horizontal, size.horizontalPadding)
            .background(backgroundFill)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
                        isPressed = false
                    }
                }
        )
    }

    private var backgroundFill: Color {
        isDisabled ? EngifyColors.surfaceMuted.opacity(0.7) : accentColor.opacity(0.10)
    }

    private var borderColor: Color {
        isDisabled ? EngifyColors.border.opacity(0.6) : accentColor.opacity(0.28)
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
