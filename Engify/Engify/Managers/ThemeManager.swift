import Combine
import SwiftUI

// MARK: - Environment Key

/// Custom environment key to access the current theme accent color throughout the app.
private struct AccentColorKey: EnvironmentKey {
    static let defaultValue: Color = EngifyColors.accent
}

extension EnvironmentValues {
    var themeAccentColor: Color {
        get { self[AccentColorKey.self] }
        set { self[AccentColorKey.self] = newValue }
    }
}

/// ThemeManager stores and persists the user's visual preferences app-wide.
///
/// WHAT IT DOES:
/// - Manages three user preferences: accent color (5 options), appearance mode (system/light/dark),
///   and font size slider (14–22pt).
/// - All changes are written to UserDefaults immediately via didSet observers.
///
/// WHEN IT SHOWS:
/// - Injected as an environment object from EngifyApp down to every view in the app.
/// - Controls the look of buttons, cards, backgrounds, and text throughout.
/// - The current settings are applied via .accentColor() and .preferredColorScheme()
///   in EngifyApp, and individual components read theme.accentColor directly.
///
/// HOW IT WORKS:
/// - @Published properties trigger UI updates automatically when changed.
/// - UserDefaults keys are namespaced under "engify_" prefixes to avoid collisions.
/// - The Color property exposed via `accentColor` maps the Accent enum to a Color value.
/// - preferredColorScheme returns an optional ColorScheme: nil means "follow system".
final class ThemeManager: ObservableObject {
    private enum Keys {
        static let accent = "engify_accent"
        static let appearance = "engify_appearance"
        static let fontSize = "engify_font_size"
    }

    enum Accent: String, CaseIterable, Identifiable {
        case Meadow, Forest, Mint, Olive, Teal
        var id: String { rawValue }

        var color: Color {
            switch self {
            case .Meadow: return Color(red: 0.28, green: 0.62, blue: 0.41)
            case .Forest: return Color(red: 0.17, green: 0.43, blue: 0.29)
            case .Mint: return Color(red: 0.22, green: 0.68, blue: 0.73)
            case .Olive: return Color(red: 0.70, green: 0.56, blue: 0.18)
            case .Teal: return Color(red: 0.18, green: 0.48, blue: 0.78)
            }
        }
    }

    enum AppearanceMode: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
    }

    @Published var accent: Accent {
        didSet {
            UserDefaults.standard.set(accent.rawValue, forKey: Keys.accent)
            objectWillChange.send()
        }
    }
    @Published var appearance: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance)
            objectWillChange.send()
        }
    }
    @Published var fontSize: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(fontSize), forKey: Keys.fontSize)
            objectWillChange.send()
        }
    }

    init() {
        let storedAccent = UserDefaults.standard.string(forKey: Keys.accent) ?? Accent.Meadow.rawValue
        let storedAppearance = UserDefaults.standard.string(forKey: Keys.appearance) ?? AppearanceMode.system.rawValue
        let storedFontSize = UserDefaults.standard.double(forKey: Keys.fontSize)

        self.accent = Accent(rawValue: storedAccent) ?? .Meadow
        self.appearance = AppearanceMode(rawValue: storedAppearance) ?? .system
        self.fontSize = storedFontSize > 0 ? CGFloat(storedFontSize) : 16
    }

    var accentColor: Color { accent.color }

    /// Convert to SwiftUI ColorScheme optional: nil => system
    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
