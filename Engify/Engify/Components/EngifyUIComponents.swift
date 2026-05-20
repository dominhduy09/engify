import SwiftUI
import Combine

// MARK: - Design Tokens

enum EngifyColors {
    private static var isHighContrastEnabled: Bool {
        UserDefaults.standard.bool(forKey: "engify.settings.high_contrast")
    }

    static let primary = Color(red: 0.11, green: 0.12, blue: 0.16)
    static let primaryLight = Color(red: 0.20, green: 0.22, blue: 0.28)

    static let accent = Color(red: 0.28, green: 0.62, blue: 0.41)
    static let accentDark = Color(red: 0.19, green: 0.47, blue: 0.31)
    static let accentLight = Color(red: 0.82, green: 0.94, blue: 0.86)

    static let sky = Color(red: 0.45, green: 0.73, blue: 0.60)
    static let sage = Color(red: 0.22, green: 0.55, blue: 0.35)
    static let coral = Color(red: 0.87, green: 0.36, blue: 0.32)
    static let warning = Color(red: 0.86, green: 0.59, blue: 0.19)

    static var canvas: Color {
        isHighContrastEnabled ? Color.white : Color(red: 0.98, green: 0.97, blue: 0.95)
    }

    static var canvasRaised: Color {
        isHighContrastEnabled ? Color(red: 0.94, green: 0.94, blue: 0.92) : Color(red: 0.95, green: 0.94, blue: 0.91)
    }

    static var surface: Color {
        isHighContrastEnabled ? Color.white : Color(red: 1.00, green: 0.99, blue: 0.98)
    }

    static var surfaceMuted: Color {
        isHighContrastEnabled ? Color(red: 0.93, green: 0.94, blue: 0.95) : Color(red: 0.95, green: 0.94, blue: 0.92)
    }

    static let surfaceDark = Color(red: 0.12, green: 0.13, blue: 0.17)
    static let surfaceDarkRaised = Color(red: 0.16, green: 0.17, blue: 0.22)

    static var border: Color {
        isHighContrastEnabled ? Color(red: 0.58, green: 0.56, blue: 0.52) : Color(red: 0.87, green: 0.84, blue: 0.80)
    }

    static var borderDark: Color {
        isHighContrastEnabled ? Color(red: 0.48, green: 0.50, blue: 0.56) : Color(red: 0.26, green: 0.27, blue: 0.34)
    }

    static var textPrimary: Color {
        isHighContrastEnabled ? Color.black : Color(red: 0.14, green: 0.14, blue: 0.18)
    }

    static var textSecondary: Color {
        isHighContrastEnabled ? Color(red: 0.22, green: 0.24, blue: 0.28) : Color(red: 0.46, green: 0.47, blue: 0.54)
    }

    static let textInverse = Color.white

    static let accentGradient = LinearGradient(
        colors: [accent, accentDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [EngifyColors.surfaceDark, EngifyColors.primary, Color.black]
                    : [EngifyColors.canvas, EngifyColors.canvasRaised, Color.white],
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
                                insertion: .scale(scale: 0.82, anchor: .topLeading).combined(with: .opacity),
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

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.32),
                                    tint.opacity(0.10),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    Color.clear,
                                    tint.opacity(0.10)
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
                                Color.white.opacity(0.72),
                                tint.opacity(0.22),
                                Color.white.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: EngifyColors.primary.opacity(shadowOpacity), radius: 24, x: 0, y: 14)
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
    let title: String
    let message: String

    var body: some View {
        EngifyCard(tint: EngifyColors.sky) {
            HStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.1)

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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ProgressBar()
            HStack(spacing: Spacing.md) {
                Button {
                    showGamificationInfoSheet = true
                    EngifyFeedback.shared.play(.tabSwitch)
                } label: {
                    StreakCounter(
                        streakDays: authManager.isGuestMode ? 0 : gamification.progress.streakDays,
                        isLocked: authManager.isGuestMode
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
                        count: authManager.isGuestMode ? 0 : gamification.progress.lingots,
                        isLocked: authManager.isGuestMode
                    )
                }
                .buttonStyle(.plain)
                .engifyJellyPress()
                .accessibilityLabel("Experience points and stars")
                .accessibilityHint("Opens information about XP, stars, and badges")

                Spacer(minLength: 0)
            }

            if authManager.isGuestMode {
                Label("Sign in to track progress", systemImage: "lock.fill")
                .font(EngifyTypography.caption)
                .foregroundStyle(EngifyColors.textSecondary)
            }
        }
        .sheet(isPresented: $showGamificationInfoSheet) {
            if #available(iOS 16.0, *) {
                GamificationInfoSheet()
                    .presentationDetents([.medium, .large])
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
                .fill(.white.opacity(0.16))
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
                        .background(.white, in: Circle())
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
                        colors: [Color.white.opacity(0.92), ringColor.opacity(0.75)],
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
        VStack(alignment: .leading, spacing: Spacing.md) {
            EngifyTopHeaderBar(
                title: title,
                subtitle: subtitle,
                showSettings: $showSettings
            )

            EngifyTopMetricsBar()
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
            if !authManager.isGuestMode {
                EngifyProfileSheet(showSettings: $showSettings)
                    .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $showSavedWordBank) {
            SavedWordBankSheet()
                .environmentObject(savedWordsManager)
        }
    }
}

private struct EngifyProfileMenu: View {
    static let menuWidth: CGFloat = 240

    @Binding var showSettings: Bool
    @Binding var showProfileSheet: Bool
    @Binding var showSavedWordBank: Bool
    @Binding var isPresented: Bool
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager
    @Environment(\.themeAccentColor) private var accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if authManager.isGuestMode {
                popoverAction(title: "Sign In / Register", systemImage: "person.crop.circle.badge.plus") {
                    isPresented = false
                    authManager.presentAccountRequired(for: .accountMenu)
                }
            } else {
                popoverAction(title: "My Profile", systemImage: "person.crop.circle") {
                    isPresented = false
                    showProfileSheet = true
                }
            }

            popoverAction(title: "Saved Word Bank", systemImage: "books.vertical.fill") {
                isPresented = false
                showSavedWordBank = true
            }

            popoverAction(title: "Settings", systemImage: "gearshape.fill") {
                isPresented = false
                showSettings = true
            }

            Divider()
                .padding(.vertical, Spacing.xxs)

            profileMenuToggle(
                title: "Sound effects",
                systemImage: learningSettings.soundEffectsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                subtitle: learningSettings.soundEffectsEnabled ? "On" : "Off",
                isOn: $learningSettings.soundEffectsEnabled
            )

            if authManager.isAuthenticated {
                Divider()
                    .padding(.vertical, Spacing.xxs)

                popoverAction(
                    title: "Sign Out",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    tint: EngifyColors.coral
                ) {
                    isPresented = false
                    Task { await authManager.signOut() }
                }
            }
        }
        .padding(Spacing.sm)
        .frame(width: Self.menuWidth, alignment: .leading)
        .engifyGlassPanel(cornerRadius: 24, tint: accentColor, shadowOpacity: 0.18)
        .zIndex(999)
    }

    private func popoverAction(title: String, systemImage: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        let foreground = tint ?? EngifyColors.textPrimary

        return Button {
            withAnimation(EngifySpring.settle) {
                action()
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(EngifyTypography.bodyStrong)
                Spacer(minLength: 0)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .frame(minHeight: 56)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                (tint ?? accentColor).opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
    }

    private func profileMenuToggle(title: String, systemImage: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EngifyColors.textPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(subtitle)
                        .font(EngifyTypography.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                }
            }

            Spacer(minLength: 0)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(minHeight: 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.16),
                            accentColor.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
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

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

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
                    profileMetric(title: "Level", value: "Lv \(gamification.progress.level)", icon: "flag.fill")
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
                    subtitle: "Access settings or safely sign out from the same place across every tab."
                )

                SecondaryButton(
                    title: "Settings",
                    systemImage: "gearshape.fill",
                    action: {
                        dismiss()
                        showSettings = true
                    }
                )

                SecondaryButton(
                    title: authManager.isLoading ? "Signing Out..." : "Sign Out",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    action: {
                        Task {
                            await authManager.signOut()
                            dismiss()
                        }
                    },
                    isDisabled: authManager.isLoading
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
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var learningSettings: LearningSettingsManager

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            SettingsView()
                .environmentObject(theme)
                .environmentObject(learningSettings)
        }
    }
}

struct SavedWordBankSheet: View {
    @EnvironmentObject private var savedWordsManager: SavedWordsManager
    @Environment(\.themeAccentColor) private var accentColor
    @State private var selectedFilter: SavedWordBankFilter = .all

    private var items: [SavedWordBankItem] {
        savedWordsManager.savedWordBankItems
    }

    private var filteredItems: [SavedWordBankItem] {
        switch selectedFilter {
        case .all:
            return items
        case .lookup:
            return items.filter { $0.source == .dictionary }
        case .vocab:
            return items.filter { $0.source == .vocabulary || $0.source == .news }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        summaryCard
                        filterTabs

                        if filteredItems.isEmpty {
                            EmptyStateView(
                                title: emptyStateTitle,
                                message: emptyStateMessage,
                                systemImage: "books.vertical"
                            )
                        } else {
                            ForEach(filteredItems) { item in
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
                    VocabularyBadge(text: "\(filteredItems.count) shown")
                    VocabularyBadge(text: "\(items.count) total saved", tint: accentColor)
                }
            }
        }
    }

    private var filterTabs: some View {
        HStack(spacing: Spacing.sm) {
            filterTab(.all, title: "All")
            filterTab(.lookup, title: "Lookup")
            filterTab(.vocab, title: "Vocab")
        }
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Saved Words Yet"
        case .lookup:
            return "No Lookup Saves Yet"
        case .vocab:
            return "No Vocab Saves Yet"
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "Save a word from Vocabulary or Dictionary and it will land here instantly."
        case .lookup:
            return "Words you save from the Lookup page will appear in this tab."
        case .vocab:
            return "Words you save from Vocab or News will appear in this tab."
        }
    }

    private func filterTab(_ filter: SavedWordBankFilter, title: String) -> some View {
        Button {
            withAnimation(EngifySpring.tabSlide) {
                selectedFilter = filter
            }
        } label: {
            Text(title)
                .font(EngifyTypography.caption.weight(.semibold))
                .foregroundStyle(selectedFilter == filter ? EngifyColors.textInverse : accentColor)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(selectedFilter == filter ? accentColor : accentColor.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .engifyJellyPress()
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

                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        VocabularyBadge(text: item.subtitle)
                        VocabularyBadge(text: item.source.label, tint: accentColor)
                    }
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

private enum SavedWordBankFilter {
    case all
    case lookup
    case vocab
}

extension View {
    func engifySettingsSheet(isPresented: Binding<Bool>) -> some View {
        modifier(EngifySettingsSheetModifier(isPresented: isPresented))
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
    let onSelect: (Int) -> Void

    @Environment(\.colorScheme) private var colorScheme

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
                                        .foregroundStyle(EngifyColors.sage)
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
                            .foregroundStyle(selectedAnswer == question.answerIndex ? EngifyColors.sage : EngifyColors.coral)

                        Text(question.explanation)
                            .font(.footnote)
                            .foregroundStyle(EngifyColors.textSecondary)
                    }
                }
            }
        }
    }

    private func optionBackground(isCorrect: Bool, isSelected: Bool) -> Color {
        if revealAnswer {
            if isCorrect {
                return EngifyColors.sage.opacity(0.14)
            } else if isSelected {
                return EngifyColors.coral.opacity(0.12)
            }
        } else if isSelected {
            return EngifyColors.accent.opacity(0.08)
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
