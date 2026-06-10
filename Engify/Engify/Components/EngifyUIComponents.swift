import SwiftUI
import Combine

// MARK: - Design Tokens

enum EngifyColors {
    private struct AccentPalette {
        let base: Color
        let dark: Color
        let light: Color
        let darkModeLight: Color
    }

    private static var isHighContrastEnabled: Bool {
        UserDefaults.standard.bool(forKey: "engify.settings.high_contrast")
    }

    private static var preferredAccent: String {
        UserDefaults.standard.string(forKey: "engify_accent") ?? ThemeManager.Accent.Meadow.rawValue
    }

    private static var preferredAppearance: String {
        UserDefaults.standard.string(forKey: "engify_appearance") ?? "system"
    }

    private static var followsDarkAppearance: Bool {
        if preferredAppearance == "dark" {
            return true
        }

        if preferredAppearance == "light" {
            return false
        }

        return UITraitCollection.current.userInterfaceStyle == .dark
    }

    private static var accentPalette: AccentPalette {
        switch preferredAccent {
        case ThemeManager.Accent.Forest.rawValue:
            return AccentPalette(
                base: Color(red: 0.17, green: 0.43, blue: 0.29),
                dark: Color(red: 0.11, green: 0.30, blue: 0.20),
                light: Color(red: 0.79, green: 0.90, blue: 0.83),
                darkModeLight: Color(red: 0.18, green: 0.25, blue: 0.21)
            )
        case ThemeManager.Accent.Mint.rawValue:
            return AccentPalette(
                base: Color(red: 0.22, green: 0.68, blue: 0.73),
                dark: Color(red: 0.14, green: 0.49, blue: 0.53),
                light: Color(red: 0.82, green: 0.95, blue: 0.96),
                darkModeLight: Color(red: 0.18, green: 0.28, blue: 0.30)
            )
        case ThemeManager.Accent.Olive.rawValue:
            return AccentPalette(
                base: Color(red: 0.70, green: 0.56, blue: 0.18),
                dark: Color(red: 0.51, green: 0.40, blue: 0.12),
                light: Color(red: 0.96, green: 0.91, blue: 0.78),
                darkModeLight: Color(red: 0.33, green: 0.27, blue: 0.18)
            )
        case ThemeManager.Accent.Teal.rawValue:
            return AccentPalette(
                base: Color(red: 0.18, green: 0.48, blue: 0.78),
                dark: Color(red: 0.12, green: 0.33, blue: 0.55),
                light: Color(red: 0.81, green: 0.89, blue: 0.97),
                darkModeLight: Color(red: 0.18, green: 0.23, blue: 0.32)
            )
        default:
            return AccentPalette(
                base: Color(red: 0.28, green: 0.62, blue: 0.41),
                dark: Color(red: 0.19, green: 0.47, blue: 0.31),
                light: Color(red: 0.82, green: 0.94, blue: 0.86),
                darkModeLight: Color(red: 0.21, green: 0.31, blue: 0.26)
            )
        }
    }

    static let primary = Color(red: 0.11, green: 0.12, blue: 0.16)
    static let primaryLight = Color(red: 0.20, green: 0.22, blue: 0.28)

    static var accent: Color { accentPalette.base }
    static var accentDark: Color { accentPalette.dark }
    static var accentLight: Color {
        followsDarkAppearance
            ? accentPalette.darkModeLight
            : accentPalette.light
    }

    static let sky = Color(red: 0.45, green: 0.73, blue: 0.60)
    static let sage = Color(red: 0.22, green: 0.55, blue: 0.35)
    static let coral = Color(red: 0.87, green: 0.36, blue: 0.32)
    static let warning = Color(red: 0.86, green: 0.59, blue: 0.19)

    static var canvas: Color {
        if followsDarkAppearance {
            return isHighContrastEnabled ? Color.black : Color(red: 0.10, green: 0.11, blue: 0.14)
        }

        return isHighContrastEnabled ? Color.white : Color(red: 0.98, green: 0.97, blue: 0.95)
    }

    static var canvasRaised: Color {
        if followsDarkAppearance {
            return isHighContrastEnabled ? Color(red: 0.14, green: 0.14, blue: 0.16) : Color(red: 0.15, green: 0.16, blue: 0.20)
        }

        return isHighContrastEnabled ? Color(red: 0.94, green: 0.94, blue: 0.92) : Color(red: 0.95, green: 0.94, blue: 0.91)
    }

    static var surface: Color {
        if followsDarkAppearance {
            return isHighContrastEnabled ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.13, green: 0.14, blue: 0.18)
        }

        return isHighContrastEnabled ? Color.white : Color(red: 1.00, green: 0.99, blue: 0.98)
    }

    static var surfaceMuted: Color {
        if followsDarkAppearance {
            return isHighContrastEnabled ? Color(red: 0.16, green: 0.17, blue: 0.20) : Color(red: 0.18, green: 0.19, blue: 0.24)
        }

        return isHighContrastEnabled ? Color(red: 0.93, green: 0.94, blue: 0.95) : Color(red: 0.95, green: 0.94, blue: 0.92)
    }

    static let surfaceDark = Color(red: 0.12, green: 0.13, blue: 0.17)
    static let surfaceDarkRaised = Color(red: 0.16, green: 0.17, blue: 0.22)

    static var border: Color {
        if followsDarkAppearance {
            return isHighContrastEnabled ? Color(red: 0.62, green: 0.64, blue: 0.70) : Color(red: 0.30, green: 0.32, blue: 0.38)
        }

        return isHighContrastEnabled ? Color(red: 0.58, green: 0.56, blue: 0.52) : Color(red: 0.87, green: 0.84, blue: 0.80)
    }

    static var borderDark: Color {
        isHighContrastEnabled ? Color(red: 0.48, green: 0.50, blue: 0.56) : Color(red: 0.26, green: 0.27, blue: 0.34)
    }

    static var textPrimary: Color {
        if followsDarkAppearance {
            return isHighContrastEnabled ? Color.white : Color(red: 0.94, green: 0.95, blue: 0.98)
        }

        return isHighContrastEnabled ? Color.black : Color(red: 0.14, green: 0.14, blue: 0.18)
    }

    static var textSecondary: Color {
        if followsDarkAppearance {
            return isHighContrastEnabled ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.72, green: 0.74, blue: 0.80)
        }

        return isHighContrastEnabled ? Color(red: 0.22, green: 0.24, blue: 0.28) : Color(red: 0.46, green: 0.47, blue: 0.54)
    }

    static let textInverse = Color.white

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum EngifyTypography {
    private static var baseFontSize: CGFloat {
        let storedSize = UserDefaults.standard.double(forKey: "engify_font_size")
        return storedSize > 0 ? CGFloat(storedSize) : 16
    }

    private static func scaledFont(
        offset: CGFloat,
        weight: Font.Weight,
        design: Font.Design
    ) -> Font {
        Font.system(size: max(12, baseFontSize + offset), weight: weight, design: design)
    }

    static var hero: Font { scaledFont(offset: 16, weight: .bold, design: .rounded) }
    static var screenTitle: Font { scaledFont(offset: 12, weight: .bold, design: .rounded) }
    static var cardTitle: Font { scaledFont(offset: 6, weight: .bold, design: .rounded) }
    static var sectionTitle: Font { scaledFont(offset: 4, weight: .bold, design: .rounded) }
    static var headline: Font { scaledFont(offset: 1, weight: .semibold, design: .rounded) }
    static var body: Font { scaledFont(offset: 0, weight: .regular, design: .default) }
    static var bodyStrong: Font { scaledFont(offset: 0, weight: .semibold, design: .default) }
    static var caption: Font { scaledFont(offset: -3, weight: .medium, design: .default) }
}

// MARK: - Background / Screen Shell

struct EngifyAppBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("engify_accent") private var preferredAccent = ThemeManager.Accent.Meadow.rawValue
    @AppStorage("engify_appearance") private var preferredAppearance = ThemeManager.AppearanceMode.system.rawValue
    @AppStorage("engify.settings.high_contrast") private var isHighContrastEnabled = false

    var body: some View {
        let _ = preferredAccent
        let _ = preferredAppearance
        let _ = isHighContrastEnabled

        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        EngifyColors.canvas,
                        EngifyColors.surfaceDark,
                        EngifyColors.surfaceDarkRaised
                    ]
                    : [EngifyColors.canvas, EngifyColors.canvasRaised, EngifyColors.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    EngifyColors.accent.opacity(colorScheme == .dark ? 0.22 : 0.14),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 360
            )
            .offset(x: -120, y: -140)

            RadialGradient(
                colors: [
                    EngifyColors.sky.opacity(colorScheme == .dark ? 0.16 : 0.08),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .offset(x: 120, y: 160)
        }
        .ignoresSafeArea()
    }
}

struct EngifyScreenScroll<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let bottomInset: CGFloat
    let content: Content
    @AppStorage("engify_accent") private var preferredAccent = ThemeManager.Accent.Meadow.rawValue
    @AppStorage("engify_appearance") private var preferredAppearance = ThemeManager.AppearanceMode.system.rawValue
    @AppStorage("engify.settings.high_contrast") private var isHighContrastEnabled = false
    @AppStorage("engify_font_size") private var preferredFontSize = 16.0
    @StateObject private var overlayCoordinator = EngifyOverlayCoordinator()

    init(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = Spacing.sectionGap,
        bottomInset: CGFloat = Spacing.screenBottomInset,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.bottomInset = bottomInset
        self.content = content()
    }

    var body: some View {
        let _ = preferredAccent
        let _ = preferredAppearance
        let _ = isHighContrastEnabled
        let _ = preferredFontSize

        ZStack {
            EngifyAppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: alignment, spacing: spacing) {
                    content
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.screenTopPadding)
                .padding(.bottom, bottomInset)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .coordinateSpace(name: EngifyOverlayCoordinator.coordinateSpaceName)
        .environmentObject(overlayCoordinator)
        .overlay(alignment: .topLeading) {
            if let presentation = overlayCoordinator.profileMenuPresentation {
                GeometryReader { proxy in
                    ZStack(alignment: .topLeading) {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(EngifySpring.settle) {
                                    overlayCoordinator.dismissProfileMenu()
                                }
                            }
                            .zIndex(998)

                        EngifyProfileMenu(
                            showSettings: presentation.showSettings,
                            showProfileSheet: presentation.showProfileSheet,
                            showSavedWordBank: presentation.showSavedWordBank,
                            isPresented: Binding(
                                get: { overlayCoordinator.profileMenuPresentation != nil },
                                set: { isPresented in
                                    if !isPresented {
                                        overlayCoordinator.dismissProfileMenu()
                                    }
                                }
                            )
                        )
                        .offset(
                            x: min(
                                max(Spacing.screenPadding, presentation.anchorFrame.minX),
                                max(Spacing.screenPadding, proxy.size.width - EngifyProfileMenu.menuWidth - Spacing.screenPadding)
                            ),
                            y: presentation.anchorFrame.maxY + Spacing.xs
                        )
                        .transition(
                            .asymmetric(
                                insertion: .identity,
                                removal: .scale(scale: 0.92, anchor: .topLeading).combined(with: .opacity)
                            )
                        )
                        .zIndex(999)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .zIndex(999)
                }
            }
        }
    }
}

struct EngifyGlassPanelModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let shadowOpacity: Double
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(baseFill)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(colorScheme == .dark ? 0.18 : 0.10),
                                    highlightColor,
                                    raisedFill.opacity(colorScheme == .dark ? 0.94 : 0.84)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    highlightColor.opacity(colorScheme == .dark ? 0.82 : 0.68),
                                    Color.clear,
                                    tint.opacity(colorScheme == .dark ? 0.16 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                borderHighlight,
                                tint.opacity(colorScheme == .dark ? 0.24 : 0.18),
                                borderBase
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: EngifyColors.primary.opacity(shadowOpacity), radius: 24, x: 0, y: 14)
    }

    private var baseFill: LinearGradient {
        LinearGradient(
            colors: [
                raisedFill.opacity(0.98),
                baseSurface.opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var baseSurface: Color {
        colorScheme == .dark ? EngifyColors.surfaceDark : EngifyColors.surface
    }

    private var raisedFill: Color {
        colorScheme == .dark ? EngifyColors.surfaceDarkRaised : EngifyColors.canvasRaised
    }

    private var highlightColor: Color {
        colorScheme == .dark ? EngifyColors.surfaceMuted : EngifyColors.surface
    }

    private var borderHighlight: Color {
        colorScheme == .dark ? EngifyColors.border.opacity(0.92) : EngifyColors.surface.opacity(0.92)
    }

    private var borderBase: Color {
        colorScheme == .dark ? EngifyColors.borderDark.opacity(0.92) : EngifyColors.border.opacity(0.72)
    }
}

extension View {
    func engifyGlassPanel(
        cornerRadius: CGFloat = 24,
        tint: Color,
        shadowOpacity: Double = 0.16
    ) -> some View {
        modifier(EngifyGlassPanelModifier(cornerRadius: cornerRadius, tint: tint, shadowOpacity: shadowOpacity))
    }
}

struct EngifyLiquidGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let shadowOpacity: Double
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    cardShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    baseSurface.opacity(0.98),
                                    tint.opacity(colorScheme == .dark ? 0.20 : 0.10),
                                    raisedSurface.opacity(colorScheme == .dark ? 0.98 : 0.94)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    cardShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    highlightColor.opacity(colorScheme == .dark ? 0.62 : 0.56),
                                    highlightColor.opacity(colorScheme == .dark ? 0.10 : 0.12),
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
                                    highlightColor.opacity(colorScheme == .dark ? 0.30 : 0.42),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: highlightHeight)
                        .offset(y: highlightOffset)
                        .blur(radius: highlightBlur)
                }
                .clipShape(cardShape)
            }
            .overlay {
                cardShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                borderHighlight,
                                tint.opacity(colorScheme == .dark ? 0.26 : 0.20),
                                borderBase
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: EngifyColors.primary.opacity(shadowOpacity), radius: 22, x: 0, y: 12)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var highlightHeight: CGFloat {
        min(92, max(68, cornerRadius * 4.5))
    }

    private var highlightOffset: CGFloat {
        -(highlightHeight * 0.52)
    }

    private var highlightBlur: CGFloat {
        cornerRadius <= 18 ? 1.2 : 1.6
    }

    private var baseSurface: Color {
        colorScheme == .dark ? EngifyColors.surfaceDarkRaised : EngifyColors.surface
    }

    private var raisedSurface: Color {
        colorScheme == .dark ? EngifyColors.surfaceMuted : EngifyColors.canvasRaised
    }

    private var highlightColor: Color {
        colorScheme == .dark ? EngifyColors.border : EngifyColors.surface
    }

    private var borderHighlight: Color {
        colorScheme == .dark ? EngifyColors.border.opacity(0.90) : EngifyColors.surface.opacity(0.96)
    }

    private var borderBase: Color {
        colorScheme == .dark ? EngifyColors.borderDark.opacity(0.96) : EngifyColors.border.opacity(0.74)
    }
}

struct EngifyLiquidGlassInputModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    inputBase.opacity(0.98),
                                    tint.opacity(isFocused ? focusedTintOpacity : idleTintOpacity),
                                    inputRaised.opacity(0.98)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    highlightColor.opacity(isFocused ? highlightTopOpacity : idleHighlightTopOpacity),
                                    highlightColor.opacity(isFocused ? highlightMidOpacity : idleHighlightMidOpacity),
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
                                    highlightColor.opacity(isFocused ? glowTopOpacity : idleGlowTopOpacity),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 48)
                        .offset(y: -22)
                        .blur(radius: 1.2)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                borderHighlight,
                                tint.opacity(isFocused ? focusedBorderTintOpacity : idleBorderTintOpacity),
                                borderBase
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 1.8 : 1
                    )
            }
            .shadow(color: tint.opacity(isFocused ? 0.18 : 0.08), radius: isFocused ? 14 : 8, x: 0, y: 6)
    }

    private var inputBase: Color {
        colorScheme == .dark ? EngifyColors.surfaceDarkRaised : EngifyColors.surface
    }

    private var inputRaised: Color {
        colorScheme == .dark ? EngifyColors.surfaceMuted : EngifyColors.canvasRaised
    }

    private var highlightColor: Color {
        colorScheme == .dark ? EngifyColors.border : EngifyColors.surface
    }

    private var borderHighlight: Color {
        colorScheme == .dark ? EngifyColors.border.opacity(0.88) : EngifyColors.surface.opacity(0.98)
    }

    private var borderBase: Color {
        colorScheme == .dark ? EngifyColors.borderDark.opacity(0.94) : EngifyColors.border.opacity(0.74)
    }

    private var focusedTintOpacity: Double { colorScheme == .dark ? 0.20 : 0.14 }
    private var idleTintOpacity: Double { colorScheme == .dark ? 0.12 : 0.07 }
    private var highlightTopOpacity: Double { colorScheme == .dark ? 0.38 : 0.58 }
    private var idleHighlightTopOpacity: Double { colorScheme == .dark ? 0.24 : 0.46 }
    private var highlightMidOpacity: Double { colorScheme == .dark ? 0.08 : 0.16 }
    private var idleHighlightMidOpacity: Double { colorScheme == .dark ? 0.04 : 0.10 }
    private var glowTopOpacity: Double { colorScheme == .dark ? 0.20 : 0.44 }
    private var idleGlowTopOpacity: Double { colorScheme == .dark ? 0.12 : 0.30 }
    private var focusedBorderTintOpacity: Double { colorScheme == .dark ? 0.52 : 0.46 }
    private var idleBorderTintOpacity: Double { colorScheme == .dark ? 0.22 : 0.16 }
}

extension View {
    func engifyLiquidGlassCard(
        cornerRadius: CGFloat = 24,
        tint: Color,
        shadowOpacity: Double = 0.16
    ) -> some View {
        modifier(EngifyLiquidGlassCardModifier(cornerRadius: cornerRadius, tint: tint, shadowOpacity: shadowOpacity))
    }

    func engifyLiquidGlassInput(
        cornerRadius: CGFloat = 18,
        tint: Color,
        isFocused: Bool
    ) -> some View {
        modifier(EngifyLiquidGlassInputModifier(cornerRadius: cornerRadius, tint: tint, isFocused: isFocused))
    }
}

@MainActor
private final class EngifyOverlayCoordinator: ObservableObject {
    static let coordinateSpaceName = "EngifyScreenOverlaySpace"

    @Published var profileMenuPresentation: EngifyProfileMenuPresentation?
    @Published var isProfileMenuInteractive = false

    func presentProfileMenu(
        anchorFrame: CGRect,
        showSettings: Binding<Bool>,
        showProfileSheet: Binding<Bool>,
        showSavedWordBank: Binding<Bool>
    ) {
        isProfileMenuInteractive = false
        profileMenuPresentation = EngifyProfileMenuPresentation(
            anchorFrame: anchorFrame,
            showSettings: showSettings,
            showProfileSheet: showProfileSheet,
            showSavedWordBank: showSavedWordBank
        )

        DispatchQueue.main.async { [weak self] in
            guard let self, self.profileMenuPresentation != nil else { return }
            self.isProfileMenuInteractive = true
        }
    }

    func updateProfileMenuAnchor(_ anchorFrame: CGRect) {
        guard let presentation = profileMenuPresentation else { return }

        profileMenuPresentation = EngifyProfileMenuPresentation(
            anchorFrame: anchorFrame,
            showSettings: presentation.showSettings,
            showProfileSheet: presentation.showProfileSheet,
            showSavedWordBank: presentation.showSavedWordBank
        )
    }

    func dismissProfileMenu() {
        isProfileMenuInteractive = false
        profileMenuPresentation = nil
    }
}

private struct EngifyProfileMenuPresentation {
    let anchorFrame: CGRect
    let showSettings: Binding<Bool>
    let showProfileSheet: Binding<Bool>
    let showSavedWordBank: Binding<Bool>
}

private struct EngifyProfileButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Surfaces

struct EngifyCard<Content: View>: View {
    private let content: Content
    var tint: Color = .clear
    var padding: CGFloat = Spacing.cardPadding

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("engify_accent") private var preferredAccent = ThemeManager.Accent.Meadow.rawValue
    @AppStorage("engify_appearance") private var preferredAppearance = ThemeManager.AppearanceMode.system.rawValue
    @AppStorage("engify.settings.high_contrast") private var isHighContrastEnabled = false

    init(
        tint: Color = .clear,
        padding: CGFloat = Spacing.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let _ = preferredAccent
        let _ = preferredAppearance
        let _ = isHighContrastEnabled

        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
    }

    private var cardFill: some ShapeStyle {
        if tint != .clear {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        tint.opacity(colorScheme == .dark ? 0.24 : 0.14),
                        baseFill.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(baseFill)
    }

    private var baseFill: Color {
        colorScheme == .dark ? EngifyColors.surfaceDarkRaised : EngifyColors.surface
    }

    private var cardBorder: Color {
        colorScheme == .dark ? EngifyColors.borderDark : EngifyColors.border
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.24) : EngifyColors.primary.opacity(0.08)
    }
}

struct EngifyCollapsibleCard<Summary: View, Detail: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    var tint: Color = EngifyColors.accent
    @Binding var isExpanded: Bool
    let summary: Summary
    let detail: Detail

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color = EngifyColors.accent,
        isExpanded: Binding<Bool>,
        @ViewBuilder summary: () -> Summary,
        @ViewBuilder detail: () -> Detail
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self._isExpanded = isExpanded
        self.summary = summary()
        self.detail = detail()
    }

    var body: some View {
        EngifyCard(tint: tint) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(alignment: .center, spacing: Spacing.md) {
                        EngifyIconBadge(systemImage: systemImage, tint: tint, size: 44)

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(title)
                                .font(EngifyTypography.headline)
                                .foregroundStyle(EngifyColors.textPrimary)

                            if let subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer(minLength: 0)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EngifyColors.textSecondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                summary

                if isExpanded {
                    Divider()
                    detail
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
}

struct CardView<Content: View>: View {
    private let content: Content
    var tint: Color = .clear

    init(tint: Color = .clear, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        EngifyCard(tint: tint) {
            content
        }
    }
}

struct EngifyIconBadge: View {
    let systemImage: String
    let tint: Color
    var size: CGFloat = 48
    var shape: RoundedRectangle = RoundedRectangle(cornerRadius: 16, style: .continuous)

    var body: some View {
        shape
            .fill(tint.opacity(0.12))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tint)
            )
    }
}

// MARK: - Reusable States

enum EngifyStateTone {
    case accent
    case info
    case success
    case warning
    case error

    var color: Color {
        switch self {
        case .accent: return EngifyColors.accent
        case .info: return EngifyColors.sky
        case .success: return EngifyColors.sage
        case .warning: return EngifyColors.warning
        case .error: return EngifyColors.coral
        }
    }
}

struct EngifyStateCard: View {
    let title: String
    let message: String
    let systemImage: String
    var tone: EngifyStateTone = .accent
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        EngifyCard(tint: tone.color) {
            VStack(spacing: Spacing.cardGap) {
                EngifyIconBadge(systemImage: systemImage, tint: tone.color, size: 64)

                VStack(spacing: Spacing.xs) {
                    Text(title)
                        .font(EngifyTypography.headline)
                        .foregroundStyle(EngifyColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if let actionTitle, let action {
                    SecondaryButton(title: actionTitle, systemImage: "arrow.clockwise", action: action)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }
}

struct EngifyLoadingCard: View {
    @Environment(\.themeAccentColor) private var accentColor
    let title: String
    let message: String

    var body: some View {
        EngifyCard(tint: accentColor) {
            HStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.1)
                    .tint(accentColor)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(EngifyTypography.headline)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(message)
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Search / Typography

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var isLoading: Bool = false
    var onSubmit: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(EngifyColors.textSecondary)
                .font(.body.weight(.semibold))

            TextField(placeholder, text: $text)
                .font(EngifyTypography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(onSubmit)

            if isLoading {
                ProgressView()
                    .scaleEffect(0.9)
            } else if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(EngifyColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(minHeight: Spacing.controlHeight)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(searchFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(searchBorder, lineWidth: 1)
        )
    }

    private var searchFill: Color {
        colorScheme == .dark ? EngifyColors.surfaceDark : EngifyColors.canvasRaised
    }

    private var searchBorder: Color {
        colorScheme == .dark ? EngifyColors.borderDark : EngifyColors.border.opacity(0.8)
    }
}

struct EngifySectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(EngifyTypography.sectionTitle)
                .foregroundStyle(EngifyColors.textPrimary)

            Text(subtitle)
                .font(EngifyTypography.body)
                .foregroundStyle(EngifyColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EngifyChipSection<Content: View, Trailing: View>: View {
    let title: String
    let systemImage: String
    private let trailing: Trailing
    private let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: systemImage)
                    .foregroundStyle(EngifyColors.textSecondary)

                Text(title)
                    .font(EngifyTypography.headline)
                    .foregroundStyle(EngifyColors.textPrimary)

                Spacer(minLength: 0)

                trailing
            }

            content
        }
    }
}

extension EngifyChipSection where Trailing == EmptyView {
    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, systemImage: systemImage, trailing: { EmptyView() }, content: content)
    }
}

struct WrapChipsView<Item: Hashable, Chip: View>: View {
    let items: [Item]
    let chip: (Item) -> Chip

    var body: some View {
        FlexibleChipsLayout(items: items, chip: chip)
    }
}

private struct FlexibleChipsLayout<Item: Hashable, Chip: View>: View {
    let items: [Item]
    let chip: (Item) -> Chip
    @State private var itemSizes: [Int: CGSize] = [:]
    @State private var availableWidth: CGFloat = 0

    private let horizontalSpacing = Spacing.xs
    private let verticalSpacing = Spacing.xs

    var body: some View {
        GeometryReader { proxy in
            let layout = layout(for: proxy.size.width)

            ZStack(alignment: .topLeading) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    chip(item)
                        .fixedSize()
                        .background(sizeReader(for: index))
                        .offset(
                            x: layout.positions[index]?.x ?? 0,
                            y: layout.positions[index]?.y ?? 0
                        )
                }
            }
            .frame(width: proxy.size.width, height: max(layout.height, 1), alignment: .topLeading)
            .onAppear {
                availableWidth = proxy.size.width
            }
            .onChange(of: proxy.size.width) { newWidth in
                availableWidth = newWidth
            }
        }
        .frame(height: max(layout(for: availableWidth).height, 1))
        .onPreferenceChange(FlexibleChipSizePreferenceKey.self) { itemSizes = $0 }
    }

    private func layout(for availableWidth: CGFloat) -> (positions: [Int: CGPoint], height: CGFloat) {
        guard availableWidth > 0, !items.isEmpty else {
            return ([:], 0)
        }

        var positions: [Int: CGPoint] = [:]
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for index in items.indices {
            let size = itemSizes[index] ?? .zero
            let chipWidth = size.width
            let chipHeight = size.height

            if currentX > 0, currentX + chipWidth > availableWidth {
                currentX = 0
                currentY += rowHeight + verticalSpacing
                rowHeight = 0
            }

            positions[index] = CGPoint(x: currentX, y: currentY)
            currentX += chipWidth + horizontalSpacing
            rowHeight = max(rowHeight, chipHeight)
        }

        return (positions, currentY + rowHeight)
    }

    private func sizeReader(for index: Int) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: FlexibleChipSizePreferenceKey.self,
                value: [index: proxy.size]
            )
        }
    }
}

private struct FlexibleChipSizePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGSize] = [:]

    static func reduce(value: inout [Int: CGSize], nextValue: () -> [Int: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct EngifyFeatureButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        Button(action: action) {
            EngifyCard(tint: accentColor) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    EngifyIconBadge(systemImage: systemImage, tint: accentColor)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(title)
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        Text(subtitle)
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }
}

struct VocabularyBadge: View {
    let text: String
    var tint: Color?
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        let color = tint ?? accentColor

        Text(text)
            .font(EngifyTypography.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct ArticlePreviewTag: View {
    let text: String
    var tint: Color? = nil
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        let color = tint ?? accentColor

        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct EngifyTopMetricsBar: View {
    @EnvironmentObject private var gamification: GamificationManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showGamificationInfoSheet = false
    @Binding var showSettings: Bool

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            EngifyProfileMenuButton(showSettings: $showSettings)

            Button {
                showGamificationInfoSheet = true
                EngifyFeedback.shared.play(.tabSwitch)
            } label: {
                StreakCounter(
                    streakDays: authManager.isGuestMode ? 1 : gamification.progress.streakDays,
                    isLocked: false
                )
            }
            .buttonStyle(.plain)
            .engifyJellyPress()
            .accessibilityLabel("Daily streak")
            .accessibilityHint("Opens information about streaks and rewards")

            Button {
                showGamificationInfoSheet = true
                EngifyFeedback.shared.play(.tabSwitch)
            } label: {
                PointsCounter(
                    count: authManager.isGuestMode ? 5 : gamification.progress.lingots,
                    isLocked: false
                )
            }
            .buttonStyle(.plain)
            .engifyJellyPress()
            .accessibilityLabel("Experience points and points")
            .accessibilityHint("Opens information about XP, points, and badges")

            Button {
                showGamificationInfoSheet = true
                EngifyFeedback.shared.play(.tabSwitch)
            } label: {
                ProgressBar()
            }
            .buttonStyle(.plain)
            .engifyJellyPress()
            .accessibilityLabel("Level progress")
            .accessibilityHint("Opens information about level progress and rewards")
        }
        .sheet(isPresented: $showGamificationInfoSheet) {
            if #available(iOS 16.0, *) {
                GamificationInfoSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            } else {
                GamificationInfoSheet()
            }
        }
    }
}

struct EngifyProfileAvatar: View {
    let style: EngifyAvatarStyle
    var size: CGFloat = 42
    var isGuestPlaceholder = false

    private var ringColor: Color {
        if isGuestPlaceholder {
            return EngifyColors.textSecondary
        }

        switch style {
        case .meadow:
            return EngifyColors.accent
        case .sky:
            return EngifyColors.sky
        case .sunrise:
            return EngifyColors.warning
        case .twilight:
            return Color(red: 0.31, green: 0.48, blue: 0.66)
        }
    }

    private var secondaryColor: Color {
        if isGuestPlaceholder {
            return EngifyColors.border
        }

        switch style {
        case .meadow:
            return Color(red: 0.63, green: 0.84, blue: 0.45)
        case .sky:
            return Color(red: 0.47, green: 0.78, blue: 0.98)
        case .sunrise:
            return Color(red: 0.99, green: 0.73, blue: 0.33)
        case .twilight:
            return Color(red: 0.45, green: 0.58, blue: 0.86)
        }
    }

    private var accentSymbol: String {
        if isGuestPlaceholder {
            return "person.crop.circle"
        }

        switch style {
        case .meadow:
            return "leaf.fill"
        case .sky:
            return "cloud.fill"
        case .sunrise:
            return "sun.max.fill"
        case .twilight:
            return "moon.stars.fill"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ringColor.opacity(0.92), secondaryColor.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(EngifyColors.surface.opacity(0.18))
                .padding(size * 0.08)

            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .padding(size * 0.24)
                .foregroundStyle(.white.opacity(0.96))

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: accentSymbol)
                        .font(.system(size: size * 0.20, weight: .bold))
                        .foregroundStyle(ringColor)
                        .padding(size * 0.10)
                        .background(EngifyColors.surface, in: Circle())
                }
            }
            .padding(size * 0.06)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [EngifyColors.surface.opacity(0.92), ringColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.5, size * 0.05)
                )
        )
        .shadow(color: EngifyColors.primary.opacity(0.16), radius: 8, x: 0, y: 4)
        .accessibilityHidden(true)
    }
}

struct EngifyGlobalTabHeader: View {
    let title: String
    let subtitle: String
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            EngifyTopMetricsBar(showSettings: $showSettings)

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(EngifyTypography.headline)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(subtitle)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
        .zIndex(20)
    }
}

struct EngifyProfileMenuButton: View {
    @Binding var showSettings: Bool
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var overlayCoordinator: EngifyOverlayCoordinator
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @Environment(\.themeAccentColor) private var accentColor
    @State private var buttonFrame: CGRect = .zero
    @State private var showProfileSheet = false
    @State private var showSavedWordBank = false

    private var isMenuPresented: Bool {
        overlayCoordinator.profileMenuPresentation != nil
    }

    var body: some View {
        Button {
            withAnimation(EngifySpring.jellyRelease) {
                if isMenuPresented {
                    overlayCoordinator.dismissProfileMenu()
                } else {
                    overlayCoordinator.presentProfileMenu(
                        anchorFrame: buttonFrame,
                        showSettings: $showSettings,
                        showProfileSheet: $showProfileSheet,
                        showSavedWordBank: $showSavedWordBank
                    )
                }
            }
            EngifyFeedback.shared.play(.tabSwitch)
        } label: {
            HStack(spacing: Spacing.xs) {
                EngifyProfileAvatar(
                    style: authManager.currentUser?.avatarStyle ?? .meadow,
                    size: 30,
                    isGuestPlaceholder: authManager.isGuestMode
                )

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(EngifyColors.textSecondary)
                    .rotationEffect(.degrees(isMenuPresented ? 180 : 0))
                    .animation(EngifySpring.settle, value: isMenuPresented)
            }
            .padding(.horizontal, Spacing.md)
            .frame(minWidth: 52, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(accentColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(accentColor.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: EngifyProfileButtonFramePreferenceKey.self,
                        value: proxy.frame(in: .named(EngifyOverlayCoordinator.coordinateSpaceName))
                    )
            }
        )
        .onPreferenceChange(EngifyProfileButtonFramePreferenceKey.self) { frame in
            buttonFrame = frame

            if isMenuPresented {
                overlayCoordinator.updateProfileMenuAnchor(frame)
            }
        }
        .accessibilityLabel("Profile options")
        .sheet(isPresented: $showProfileSheet) {
            if #available(iOS 16.0, *) {
                if !authManager.isGuestMode {
                    EngifyProfileSheet(showSettings: $showSettings)
                        .environmentObject(authManager)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            } else {
                if !authManager.isGuestMode {
                    EngifyProfileSheet(showSettings: $showSettings)
                        .environmentObject(authManager)
                }
            }
        }
        .sheet(isPresented: $showSavedWordBank) {
            if #available(iOS 16.0, *) {
                SavedWordBankSheet()
                    .environmentObject(savedWordsManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            } else {
                SavedWordBankSheet()
                    .environmentObject(savedWordsManager)
            }
        }
    }
}

private struct EngifyProfileMenu: View {
    static let menuWidth: CGFloat = 192

    @Binding var showSettings: Bool
    @Binding var showProfileSheet: Bool
    @Binding var showSavedWordBank: Bool
    @Binding var isPresented: Bool
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.themeAccentColor) private var accentColor
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("engify_appearance") private var preferredAppearance = ThemeManager.AppearanceMode.system.rawValue
    @State private var menuScale: CGFloat = 0.8
    @State private var menuOpacity = 0.0

    private func presentSettingsAfterDismissal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showSettings = true
        }
    }

    var body: some View {
        let _ = preferredAppearance

        VStack(alignment: .leading, spacing: 0) {
            compactMenuAction(title: "Profile", systemImage: "person.crop.circle") {
                if authManager.isGuestMode {
                    isPresented = false
                    authManager.presentAccountRequired(for: .accountMenu)
                } else {
                    isPresented = false
                    showProfileSheet = true
                }
            }

            menuDivider()

            compactMenuAction(title: "Saved", systemImage: "bookmark.fill") {
                isPresented = false
                showSavedWordBank = true
            }

            menuDivider()

            compactMenuAction(title: "Settings", systemImage: "gearshape.fill") {
                isPresented = false
                presentSettingsAfterDismissal()
            }

            if authManager.isAuthenticated {
                menuDivider(topPadding: Spacing.xs)

                compactMenuAction(
                    title: "Sign Out",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    tint: EngifyColors.coral,
                    showsDisclosure: false
                ) {
                    isPresented = false
                    Task { await authManager.signOut() }
                }
            }
        }
        .padding(Spacing.xs)
        .frame(width: Self.menuWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .scaleEffect(menuScale, anchor: .topLeading)
        .opacity(menuOpacity)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: backgroundBaseColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: backgroundTintColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(menuBorderColor, lineWidth: 1)
        }
        .shadow(color: menuShadowColor, radius: 18, x: 0, y: 10)
        .onAppear {
            animateMenuAppearance()
        }
        .zIndex(999)
    }

    private func compactMenuAction(
        title: String,
        systemImage: String,
        tint: Color? = nil,
        showsDisclosure: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        let foreground = tint ?? EngifyColors.textPrimary

        return Button {
            withAnimation(EngifySpring.settle) {
                action()
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                menuIcon(systemImage: systemImage, tint: tint)

                Text(title)
                    .font(EngifyTypography.bodyStrong)

                Spacer(minLength: 0)

                if showsDisclosure {
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 11)
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: actionBackgroundColors(tint: tint),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(actionBorderColor, lineWidth: 0.9)
                    )
            }
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }

    private func animateMenuAppearance() {
        menuScale = 0.8
        menuOpacity = 0

        withAnimation(.spring(response: 0.32, dampingFraction: 0.52, blendDuration: 0)) {
            menuScale = 1.03
            menuOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.78, blendDuration: 0)) {
                menuScale = 1
            }
        }
    }

    @ViewBuilder
    private func menuDivider(topPadding: CGFloat = 0) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        dividerEdgeColor,
                        accentColor.opacity(0.28),
                        dividerEdgeColor
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.top, topPadding)
            .padding(.horizontal, Spacing.md)
    }

    private func menuIcon(systemImage: String, tint: Color?) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: iconBackgroundColors(tint: tint),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 28, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(iconBorderColor, lineWidth: 0.8)
            )
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint ?? accentColor)
            )
    }

    private var backgroundBaseColors: [Color] {
        if colorScheme == .dark {
            return [
                EngifyColors.surfaceDarkRaised.opacity(0.98),
                EngifyColors.surfaceDark.opacity(0.96)
            ]
        }

        return [
            EngifyColors.surface.opacity(0.98),
            EngifyColors.canvasRaised.opacity(0.96)
        ]
    }

    private var backgroundTintColors: [Color] {
        if colorScheme == .dark {
            return [
                accentColor.opacity(0.18),
                EngifyColors.surfaceMuted.opacity(0.78)
            ]
        }

        return [
            accentColor.opacity(0.10),
            EngifyColors.surface.opacity(0.76)
        ]
    }

    private var menuBorderColor: Color {
        colorScheme == .dark
            ? EngifyColors.border.opacity(0.92)
            : EngifyColors.border.opacity(0.82)
    }

    private var menuShadowColor: Color {
        colorScheme == .dark
            ? .black.opacity(0.24)
            : EngifyColors.primary.opacity(0.12)
    }

    private var actionBorderColor: Color {
        colorScheme == .dark
            ? EngifyColors.border.opacity(0.86)
            : EngifyColors.border.opacity(0.60)
    }

    private var dividerEdgeColor: Color {
        colorScheme == .dark
            ? EngifyColors.border.opacity(0.34)
            : EngifyColors.border.opacity(0.22)
    }

    private var iconBorderColor: Color {
        colorScheme == .dark
            ? EngifyColors.border.opacity(0.84)
            : EngifyColors.border.opacity(0.58)
    }

    private func actionBackgroundColors(tint: Color?) -> [Color] {
        if colorScheme == .dark {
            return [
                EngifyColors.surfaceMuted.opacity(0.94),
                (tint ?? accentColor).opacity(0.14)
            ]
        }

        return [
            EngifyColors.surface.opacity(0.96),
            (tint ?? accentColor).opacity(0.08)
        ]
    }

    private func iconBackgroundColors(tint: Color?) -> [Color] {
        if colorScheme == .dark {
            return [
                EngifyColors.surfaceMuted.opacity(0.94),
                (tint ?? accentColor).opacity(0.16)
            ]
        }

        return [
            EngifyColors.canvasRaised.opacity(0.96),
            (tint ?? accentColor).opacity(0.10)
        ]
    }
}

struct EngifyTopHeaderBar: View {
    let title: String
    let subtitle: String
    @Binding var showSettings: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            EngifyProfileMenuButton(showSettings: $showSettings)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(title)
                    .font(EngifyTypography.headline)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text(subtitle)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

struct EngifyProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var gamification: GamificationManager
    @Environment(\.themeAccentColor) private var accentColor

    @Binding var showSettings: Bool

    @State private var displayName = ""
    @State private var selectedAvatarStyle: EngifyAvatarStyle = .meadow
    @State private var localMessage: String?
    @State private var showDeleteAccountConfirmation = false

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    private func presentSettingsAfterDismissal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showSettings = true
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        summaryCard
                        metricsCard
                        profileFormCard
                        actionsCard
                    }
                    .padding(Spacing.screenPadding)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            syncDraftFromUser()
            localMessage = authManager.consumeProfileUpdateMessage()
        }
        .onChange(of: authManager.currentUser) { _ in
            syncDraftFromUser()
        }
        .onChange(of: authManager.profileUpdateMessage) { message in
            if let message {
                localMessage = message
            }
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    let didDelete = await authManager.deleteAccount()
                    if didDelete {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes your Engify account and associated learning data from the app database. This action cannot be undone.")
        }
    }

    private var summaryCard: some View {
        EngifyCard(tint: accentColor) {
            HStack(alignment: .center, spacing: Spacing.lg) {
                EngifyProfileAvatar(style: selectedAvatarStyle, size: 64)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(authManager.currentUser?.displayName ?? "Learner")
                        .font(EngifyTypography.cardTitle)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(authManager.currentUser?.email ?? "No email connected")
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .lineLimit(1)

                    if let localMessage, !localMessage.isEmpty {
                        Text(localMessage)
                            .font(EngifyTypography.caption)
                            .foregroundStyle(accentColor)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var metricsCard: some View {
        EngifyCard {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                EngifySectionHeader(
                    title: "Account Metrics",
                    subtitle: "A quick snapshot of your current learning momentum."
                )

                HStack(spacing: Spacing.md) {
                    profileMetric(title: "Level", value: "Lv \(gamification.progress.resolvedLevel)", icon: "flag.fill")
                    profileMetric(title: "Streak", value: "\(gamification.progress.streakDays) days", icon: "flame.fill")
                }

                HStack(spacing: Spacing.md) {
                    profileMetric(title: "Points", value: "\(gamification.progress.lingots)", icon: "star.fill")
                    profileMetric(title: "XP", value: "\(gamification.progress.xp)", icon: "bolt.fill")
                }
            }
        }
    }

    private var profileFormCard: some View {
        EngifyCard {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                EngifySectionHeader(
                    title: "Edit Profile",
                    subtitle: "Update your display name and choose the avatar style used in the global header."
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Display Name")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    TextField("Your name", text: $displayName)
                        .font(EngifyTypography.body)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, Spacing.lg)
                        .frame(minHeight: Spacing.controlHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(EngifyColors.canvasRaised)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Profile Image Style")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    LazyVGrid(columns: columns, spacing: Spacing.sm) {
                        ForEach(EngifyAvatarStyle.allCases) { style in
                            profileAvatarOption(style)
                        }
                    }
                }

                if let errorMessage = authManager.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.coral)
                }

                PrimaryButton(
                    title: authManager.isLoading ? "Saving..." : "Save Profile",
                    systemImage: "checkmark.circle.fill",
                    action: saveProfile,
                    isDisabled: authManager.isLoading,
                    feedbackEvent: .successPop
                )
            }
        }
    }

    private var actionsCard: some View {
        EngifyCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                EngifySectionHeader(
                    title: "Account Actions",
                    subtitle: "Access settings, review your legal options, sign out, or permanently delete your account."
                )

                SecondaryButton(
                    title: "Settings",
                    systemImage: "gearshape.fill",
                    action: {
                        dismiss()
                        presentSettingsAfterDismissal()
                    }
                )

                if let deletionMessage = authManager.accountDeletionMessage, !deletionMessage.isEmpty {
                    Text(deletionMessage)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(accentColor)
                }

                SecondaryButton(
                    title: authManager.isLoading ? "Signing Out..." : "Sign Out",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    action: {
                        Task {
                            await authManager.signOut()
                            dismiss()
                        }
                    }, isDisabled: authManager.isLoading, tint: EngifyColors.coral
                )

                SecondaryButton(
                    title: authManager.isLoading ? "Deleting..." : "Delete Account",
                    systemImage: "trash.fill",
                    action: {
                        showDeleteAccountConfirmation = true
                    },
                    isDisabled: authManager.isLoading,
                    tint: EngifyColors.coral
                )
            }
        }
    }

    private func profileMetric(title: String, value: String, icon: String) -> some View {
        EngifyCard(tint: accentColor, padding: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                EngifyIconBadge(systemImage: icon, tint: accentColor, size: 42)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    Text(value)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func profileAvatarOption(_ style: EngifyAvatarStyle) -> some View {
        Button {
            selectedAvatarStyle = style
        } label: {
            HStack(spacing: Spacing.md) {
                EngifyProfileAvatar(style: style, size: 48)

                Text(style.rawValue.capitalized)
                    .font(EngifyTypography.bodyStrong)
                    .foregroundStyle(EngifyColors.textPrimary)

                Spacer(minLength: 0)

                Image(systemName: selectedAvatarStyle == style ? "checkmark.circle.fill" : "circle")
                    .font(.headline)
                    .foregroundStyle(selectedAvatarStyle == style ? accentColor : EngifyColors.textSecondary.opacity(0.45))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selectedAvatarStyle == style ? accentColor.opacity(0.12) : EngifyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selectedAvatarStyle == style ? accentColor.opacity(0.30) : EngifyColors.border.opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }

    private func saveProfile() {
        Task {
            let wasSaved = await authManager.updateProfile(
                displayName: displayName,
                avatarStyle: selectedAvatarStyle
            )

            if wasSaved {
                localMessage = authManager.consumeProfileUpdateMessage()
            }
        }
    }

    private func syncDraftFromUser() {
        displayName = authManager.currentUser?.displayName ?? ""
        selectedAvatarStyle = authManager.currentUser?.avatarStyle ?? .meadow
    }
}

private struct EngifySettingsSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let initialSection: SettingsFocusSection?
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            if #available(iOS 16.0, *) {
                SettingsView(initialSection: initialSection)
                    .environmentObject(authManager)
                    .environmentObject(theme)
                    .environmentObject(learningSettings)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            } else {
                SettingsView(initialSection: initialSection)
                    .environmentObject(authManager)
                    .environmentObject(theme)
                    .environmentObject(learningSettings)
            }
        }
    }
}

struct SavedWordBankSheet: View {
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @Environment(\.themeAccentColor) private var accentColor

    private var items: [SavedWordBankItem] {
        savedWordsManager.savedWordBankItems
    }

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        summaryCard

                        if items.isEmpty {
                            EmptyStateView(
                                title: "No Saved Words Yet",
                                message: "Save a word from Lookup, Vocab, or News and it will land here instantly.",
                                systemImage: "books.vertical"
                            )
                        } else {
                            ForEach(items) { item in
                                savedWordCard(item)
                            }
                        }
                    }
                    .padding(Spacing.screenPadding)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Saved Word Bank")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var summaryCard: some View {
        EngifyCard(tint: accentColor) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Your personal study vault")
                    .font(EngifyTypography.cardTitle)
                    .foregroundStyle(EngifyColors.textPrimary)

                Text("Jump back into saved vocabulary, review dictionary finds, and keep your strongest words close.")
                    .font(EngifyTypography.body)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: Spacing.sm) {
                    VocabularyBadge(text: "\(items.count) saved", tint: accentColor)
                }
            }
        }
    }

    private func savedWordCard(_ item: SavedWordBankItem) -> some View {
        EngifyCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(item.title)
                            .font(EngifyTypography.cardTitle)
                            .foregroundStyle(EngifyColors.textPrimary)

                        if !item.phonetic.isEmpty {
                            Text(item.phonetic)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(EngifyColors.textSecondary)
                        }
                    }

                    Spacer(minLength: 0)

                    VocabularyBadge(text: item.subtitle)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Meaning")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    Text(item.detail)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Example")
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)

                    Text("“\(item.example)”")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(EngifyColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

extension View {
    func engifySettingsSheet(
        isPresented: Binding<Bool>,
        initialSection: SettingsFocusSection? = nil
    ) -> some View {
        modifier(EngifySettingsSheetModifier(isPresented: isPresented, initialSection: initialSection))
    }
}

// MARK: - Settings Components

struct EngifySettingsSection<Content: View>: View {
    let title: String
    let subtitle: String
    let tag: String?
    let content: Content

    init(title: String, subtitle: String, tag: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.tag = tag
        self.content = content()
    }

    var body: some View {
        EngifyCard {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .center, spacing: Spacing.sm) {
                        Text(title)
                            .font(EngifyTypography.headline)
                            .foregroundStyle(EngifyColors.textPrimary)

                        if let tag {
                            EngifySettingsBadge(text: tag)
                        }

                        Spacer(minLength: 0)
                    }

                    Text(subtitle)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
        }
    }
}

struct EngifySettingsBadge: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(EngifyColors.warning)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(EngifyColors.warning.opacity(0.14))
            .clipShape(Capsule())
    }
}

struct EngifySettingToggleRow: View {
    let title: String
    let subtitle: String
    let tag: String?
    @Binding var isOn: Bool
    @Environment(\.themeAccentColor) private var accentColor

    init(title: String, subtitle: String, tag: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.tag = tag
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    Text(title)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    if let tag {
                        EngifySettingsBadge(text: tag)
                    }
                }

                Text(subtitle)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(accentColor)
    }
}

struct EngifySettingSliderRow: View {
    let title: String
    let subtitle: String
    let tag: String?
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let valueLabel: (Double) -> String
    @Environment(\.themeAccentColor) private var accentColor

    init(
        title: String,
        subtitle: String,
        tag: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        valueLabel: @escaping (Double) -> String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.tag = tag
        self.value = value
        self.range = range
        self.step = step
        self.valueLabel = valueLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(alignment: .center, spacing: Spacing.sm) {
                        Text(title)
                            .font(EngifyTypography.bodyStrong)
                            .foregroundStyle(EngifyColors.textPrimary)

                        if let tag {
                            EngifySettingsBadge(text: tag)
                        }
                    }

                    Text(subtitle)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(valueLabel(value.wrappedValue))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Slider(value: value, in: range, step: step)
                .tint(accentColor)
        }
    }
}

struct EngifySettingOptionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? EngifyColors.textInverse : EngifyColors.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(backgroundFill)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var backgroundFill: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(EngifyColors.surfaceMuted)
    }
}

// MARK: - Quiz Components

struct MultipleChoiceQuestionCard: View {
    let question: Question
    let selectedAnswer: Int?
    let revealAnswer: Bool
    var showsExplanation: Bool = true
    let onSelect: (Int) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        EngifyCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(question.prompt)
                    .font(EngifyTypography.headline)
                    .foregroundStyle(EngifyColors.textPrimary)

                ForEach(question.options.indices, id: \.self) { index in
                    let isSelected = selectedAnswer == index
                    let isCorrect = question.answerIndex == index

                    Button {
                        withAnimation(EngifySpring.jellyRelease) {
                            onSelect(index)
                        }
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Text(question.options[index])
                                .font(EngifyTypography.body)
                                .foregroundStyle(EngifyColors.textPrimary)

                            Spacer(minLength: 0)

                            if revealAnswer {
                                if isCorrect {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(accentColor)
                                } else if isSelected {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(EngifyColors.coral)
                                }
                            }
                        }
                        .padding(.vertical, Spacing.md)
                        .padding(.horizontal, Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(optionBackground(isCorrect: isCorrect, isSelected: isSelected))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .engifyJellyPress()
                }

                if revealAnswer, let selectedAnswer {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(selectedAnswer == question.answerIndex ? "Correct" : "Incorrect")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(selectedAnswer == question.answerIndex ? accentColor : EngifyColors.coral)

                        if showsExplanation {
                            Text(question.explanation)
                                .font(.footnote)
                                .foregroundStyle(EngifyColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func optionBackground(isCorrect: Bool, isSelected: Bool) -> Color {
        if revealAnswer {
            if isCorrect {
                return accentColor.opacity(0.14)
            } else if isSelected {
                return EngifyColors.coral.opacity(0.12)
            }
        } else if isSelected {
            return accentColor.opacity(0.08)
        }

        return colorScheme == .dark ? EngifyColors.surfaceDark : EngifyColors.surfaceMuted
    }
}

// MARK: - Helpers

func highlightedArticleText(_ text: String, difficultWords: [String]) -> AttributedString {
    var attributedText = AttributedString(text)

    for word in difficultWords {
        if let range = attributedText.range(of: word) {
            attributedText[range].foregroundColor = EngifyColors.accent
            attributedText[range].font = .headline
        }
    }

    return attributedText
}
