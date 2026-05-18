import SwiftUI

/// Theme customization form embedded inside SettingsView.
///
/// WHAT IT SHOWS:
/// - Section 1 (Accent color): 5 colored circles in an HStack. Selected color
///   shows a white checkmark overlay. Tapping a color updates theme.accent.
/// - Section 2 (Appearance): Segmented picker: System / Light / Dark.
/// - Section 3 (Font size): "A" label, Slider (14–22pt), "A" label at larger size.
///
/// WHEN IT SHOWS:
/// - Embedded inside SettingsView, which is presented as a sheet from HomeView.
///
/// HOW IT WORKS:
/// - Directly mutates ThemeManager properties via @EnvironmentObject binding.
/// - All changes persist immediately via UserDefaults through ThemeManager's didSet.
struct ThemePickerView: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Form {
            Section(header: Text("Accent color")) {
                HStack(spacing: 12) {
                    ForEach(ThemeManager.Accent.allCases) { accent in
                        Button(action: { theme.accent = accent }) {
                            Circle()
                                .fill(accent.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Group {
                                        if theme.accent == accent {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)

                Text("All accent options are tuned to the app's green learning brand.")
                    .font(.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
            }

            Section(header: Text("Appearance")) {
                Picker("Appearance", selection: $theme.appearance) {
                    ForEach(ThemeManager.AppearanceMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Font size")) {
                HStack {
                    Text("A")
                    Slider(value: Binding(get: { Double(theme.fontSize) }, set: { theme.fontSize = CGFloat($0) }), in: 14...22, step: 1)
                    Text("A")
                        .font(.system(size: 20))
                }
            }
        }
    }
}

struct ThemePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ThemePickerView()
            .environmentObject(ThemeManager())
    }
}
