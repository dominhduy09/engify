import SwiftUI

/// Production-grade settings sheet presented from HomeView.
///
/// WHAT IT SHOWS:
/// - A learning profile summary card at the top.
/// - Learning goal controls that capture the user's primary motivation.
/// - AI tutor customization for explanation depth and correction style.
/// - Speaking and review preferences with permission status badges.
/// - Notification controls with time picker and permission checks.
/// - Microphone and voice controls with permission status.
/// - Advanced learning toggles (grammar, definitions, difficulty lock, etc.).
/// - Accessibility and appearance controls.
///
/// WHEN IT SHOWS:
/// - Presented as a sheet from HomeView when the user taps the gear icon.
/// - All settings mutate LearningSettingsManager with validation and persistence.
///
/// HOW IT WORKS:
/// - LearningSettingsManager handles all persistence, validation, and permission checks.
/// - Permission status badges show current system permission state.
/// - Important toggles like notifications/microphone include request buttons if denied.
/// - All values validate on load; corrupted settings reset to defaults.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var settings: LearningSettingsManager
    
    @State private var requestingNotificationPermission = false
    @State private var requestingMicrophonePermission = false
    @State private var showStorageWarning = false
    @State private var showSaveConfirmation = false
    @State private var saveConfirmationTask: DispatchWorkItem?
    @State private var settingsSnapshot = ""
    @State private var showPresetConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showAppIconPicker = false
    @State private var selectedAppIconOption = AppIconOption.current(from: nil)
    @State private var appIconStatusMessage: String?
    @State private var appIconStatusType: StatusBanner.BannerType = .success
    @State private var appIconStatusTask: DispatchWorkItem?
    @State private var pendingPreset: SettingsPreset?
    private let betaTag = "Beta"

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        statusSection

                        if showSaveConfirmation {
                            saveConfirmationBanner
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        overviewCard
                        settingsPresetSection
                        learningGoalSection
                        aiTutorSection
                        speakingSection
                        practiceSection
                        dictionaryAPISection
                        notificationSection
                        appPreferencesSection
                        advancedLearningSection
                        accessibilitySection
                        appearanceSection
                        privacySection
                        legalSection
                        resetSection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showSaveConfirmation)
        .onAppear {
            settingsSnapshot = currentSettingsSnapshot
            refreshCurrentAppIconSelection()
        }
        .onChange(of: currentSettingsSnapshot) { newSnapshot in
            guard !settingsSnapshot.isEmpty, newSnapshot != settingsSnapshot else { return }
            settingsSnapshot = newSnapshot
            showChangesSaved()
        }
        .onDisappear {
            saveConfirmationTask?.cancel()
            appIconStatusTask?.cancel()
        }
        .alert("Storage Warning", isPresented: $showStorageWarning) {
            Button("Delete", role: .destructive) {
                settings.voiceHistoryEnabled = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Voice history is using \(formatBytes(settings.voiceHistoryStorageUsage)). Delete to free space?")
        }
        .alert("Apply Preset", isPresented: $showPresetConfirmation) {
            Button("Apply", role: .destructive) {
                if let preset = pendingPreset {
                    settings.applyPreset(preset)
                    pendingPreset = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingPreset = nil
            }
        } message: {
            if let preset = pendingPreset {
                Text("This will replace your current settings with the \"\(preset.title)\" preset. Notification and microphone settings won't change.")
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
            Text("This permanently removes your Engify account and associated synced learning data. This action cannot be undone.")
        }
        .sheet(isPresented: $showAppIconPicker) {
            AppIconPickerSheet(
                selectedOption: selectedAppIconOption,
                onSelect: { option in
                    Task {
                        await applyAppIcon(option)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if let errorMessage = authManager.errorMessage, !errorMessage.isEmpty {
            StatusBanner(message: errorMessage, type: .error)
        }

        if let deletionMessage = authManager.accountDeletionMessage, !deletionMessage.isEmpty {
            StatusBanner(message: deletionMessage, type: .success)
        }

        if let appIconStatusMessage, !appIconStatusMessage.isEmpty {
            StatusBanner(message: appIconStatusMessage, type: appIconStatusType)
        }
    }

    private var overviewCard: some View {
        EngifyCard(tint: theme.accentColor) {
            VStack(alignment: .center, spacing: Spacing.md) {
                Button {
                    showAppIconPicker = true
                } label: {
                    AppIconPreview(option: selectedAppIconOption, size: 78)
                        .shadow(color: theme.accentColor.opacity(0.16), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change Home Screen app icon")
                .accessibilityHint("Opens Home Screen icon choices for Engify")

                VStack(alignment: .center, spacing: Spacing.xs) {
                    Text("Learning preferences")
                        .font(.headline)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text("Adjust how Engify teaches you.")
                        .font(.subheadline)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        showAppIconPicker = true
                    } label: {
                        Text("Tap to change the app icon")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var settingsPresetSection: some View {
        EngifySettingsSection(
            title: "Quick setup",
            subtitle: "Apply a curated preset to configure all settings at once, or customize below."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(Array(SettingsPreset.allCases.enumerated()), id: \.element.id) { index, preset in
                    Button {
                        if settings.activePreset == preset {
                            // Already active — no action needed
                        } else {
                            pendingPreset = preset
                            showPresetConfirmation = true
                        }
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: preset.icon)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(preset.tintColor)
                                .frame(width: 36, height: 36)
                                .background(preset.tintColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                HStack(spacing: Spacing.sm) {
                                    Text(preset.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(EngifyColors.textPrimary)

                                    if settings.activePreset == preset {
                                        Text("Active")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(EngifyColors.textInverse)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(preset.tintColor)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(preset.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: settings.activePreset == preset ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(settings.activePreset == preset ? preset.tintColor : EngifyColors.textSecondary.opacity(0.4))
                        }
                        .padding(.vertical, Spacing.sm)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < SettingsPreset.allCases.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var learningGoalSection: some View {
        let goals: [(key: String, title: String, subtitle: String)] = [
            ("daily", "Daily communication", "Focus on practical every-day English"),
            ("travel", "Travel", "Use English confidently on trips"),
            ("work", "Work", "Prepare for meetings, emails, and interviews"),
            ("study", "Study", "Build academic vocabulary and reading skill"),
            ("exam", "IELTS / TOEFL", "Train for structured exam performance")
        ]
        
        return EngifySettingsSection(
            title: "Primary learning goal",
            subtitle: "Engify adapts vocabulary, reading, and practice to match your purpose."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(goals.indices, id: \.self) { index in
                    let goal = goals[index]

                    Button {
                        settings.learningGoal = goal.key
                    } label: {
                        HStack(alignment: .top, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(goal.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(EngifyColors.textPrimary)

                                Text(goal.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: settings.learningGoal == goal.key ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(settings.learningGoal == goal.key ? theme.accentColor : EngifyColors.textSecondary.opacity(0.5))
                        }
                        .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.plain)

                    if index < goals.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var aiTutorSection: some View {
        let depthOptions: [(key: String, title: String)] = [
            ("simple", "Simple"),
            ("balanced", "Balanced"),
            ("detailed", "Detailed")
        ]

        let styleOptions: [(key: String, title: String)] = [
            ("gentle", "Gentle"),
            ("balanced", "Balanced"),
            ("strict", "Strict")
        ]

        return EngifySettingsSection(
            title: "AI tutor customization",
            subtitle: "Tune how much help and how strongly the tutor corrects you."
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Explanation depth")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(depthOptions, id: \.key) { option in
                            EngifySettingOptionChip(
                                title: option.title,
                                isSelected: settings.explanationDepth == option.key
                            ) {
                                settings.explanationDepth = option.key
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Correction style")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(styleOptions, id: \.key) { option in
                            EngifySettingOptionChip(
                                title: option.title,
                                isSelected: settings.correctionStyle == option.key
                            ) {
                                settings.correctionStyle = option.key
                            }
                        }
                    }
                }

                EngifySettingToggleRow(
                    title: "Show example sentences",
                    subtitle: "Display more examples when you tap a difficult word.",
                    isOn: $settings.generateExtraExamples
                )

                EngifySettingToggleRow(
                    title: "Show grammar corrections",
                    subtitle: "Inline hints for grammar and usage mistakes.",
                    isOn: $settings.showGrammarCorrections
                )
            }
        }
    }

    private var speakingSection: some View {
        let speeds: [(key: String, title: String)] = [
            ("slow", "Slow"),
            ("normal", "Normal"),
            ("fast", "Fast")
        ]

        let models: [(key: String, title: String)] = [
            ("us_english", "US English"),
            ("uk_english", "UK English"),
            ("australian", "Australian")
        ]

        return EngifySettingsSection(
            title: "Speaking practice",
            subtitle: "Customize pronunciation feedback and audio settings."
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Microphone access")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EngifyColors.textPrimary)

                        HStack(spacing: Spacing.sm) {
                            Image(systemName: settings.microphonePermissionStatus.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(settings.microphonePermissionStatus.color)

                            Text(settings.microphonePermissionStatus.rawValue)
                                .font(.caption)
                                .foregroundStyle(EngifyColors.textSecondary)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: $settings.microphoneEnabled)
                        .labelsHidden()
                        .tint(theme.accentColor)

                    if settings.microphonePermissionStatus != .granted {
                        Button(requestingMicrophonePermission ? "Requesting..." : "Request") {
                            requestingMicrophonePermission = true
                            Task {
                                _ = await settings.requestMicrophonePermission()
                                requestingMicrophonePermission = false
                            }
                        }
                        .disabled(requestingMicrophonePermission)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EngifyColors.coral)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Speaking speed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(speeds, id: \.key) { option in
                            EngifySettingOptionChip(
                                title: option.title,
                                isSelected: settings.speakingSpeed == option.key
                            ) {
                                settings.speakingSpeed = option.key
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Pronunciation model")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(models, id: \.key) { option in
                            EngifySettingOptionChip(
                                title: option.title,
                                isSelected: settings.pronunciationModel == option.key
                            ) {
                                settings.pronunciationModel = option.key
                            }
                        }
                    }
                }

                EngifySettingToggleRow(
                    title: "Pronunciation feedback",
                    subtitle: "Show transcript and scoring after you speak.",
                    isOn: $settings.speechFeedbackEnabled
                )

                EngifySettingToggleRow(
                    title: "Show transcript",
                    subtitle: "Display the typed version of your speech for comparison.",
                    isOn: $settings.transcriptVisible
                )

                EngifySettingToggleRow(
                    title: "Repeat pronunciation",
                    subtitle: "Automatically replay word audio after each phrase.",
                    isOn: $settings.repeatPronunciation
                )
            }
        }
    }

    private var practiceSection: some View {
        EngifySettingsSection(
            title: "Practice cadence",
            subtitle: "Control daily targets and how much content Engify recommends."
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                EngifySettingSliderRow(
                    title: "New words per day",
                    subtitle: "Keeps your learning pace sustainable.",
                    value: Binding(
                        get: { Double(settings.newWordsPerDay) },
                        set: { settings.newWordsPerDay = Int($0) }
                    ),
                    range: 3...20,
                    step: 1
                ) { value in
                    "\(Int(value)) words"
                }

                EngifySettingSliderRow(
                    title: "Review limit per day",
                    subtitle: "Caps how many review items before Engify suggests a break.",
                    value: Binding(
                        get: { Double(settings.reviewLimitPerDay) },
                        set: { settings.reviewLimitPerDay = Int($0) }
                    ),
                    range: 5...40,
                    step: 1
                ) { value in
                    "\(Int(value)) reviews"
                }

                EngifySettingToggleRow(
                    title: "Difficulty lock",
                    subtitle: "Prevent jumping to harder levels without mastering current level.",
                    isOn: $settings.difficultyLock
                )
            }
        }
    }

    private var notificationSection: some View {
        EngifySettingsSection(
            title: "Reminders and habits",
            subtitle: "Keep streaks alive with timely nudges, but avoid notification overload."
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Notifications enabled")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EngifyColors.textPrimary)

                        HStack(spacing: Spacing.sm) {
                            Image(systemName: settings.notificationPermissionStatus.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(settings.notificationPermissionStatus.color)

                            Text(settings.notificationPermissionStatus.rawValue)
                                .font(.caption)
                                .foregroundStyle(EngifyColors.textSecondary)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: $settings.notificationsEnabled)
                        .labelsHidden()
                        .tint(theme.accentColor)
                        .disabled(settings.notificationPermissionStatus != .granted)

                    if settings.notificationPermissionStatus != .granted {
                        Button(requestingNotificationPermission ? "Requesting..." : "Request") {
                            requestingNotificationPermission = true
                            Task {
                                _ = await settings.requestNotificationPermission()
                                requestingNotificationPermission = false
                            }
                        }
                        .disabled(requestingNotificationPermission)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EngifyColors.coral)
                    }
                }

                if settings.notificationPermissionStatus == .granted && settings.notificationsEnabled {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        EngifySettingToggleRow(
                            title: "Daily reminder",
                            subtitle: "Send a reminder when it's time for your study session.",
                            isOn: $settings.dailyReminderEnabled
                        )

                        if settings.dailyReminderEnabled {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Reminder time")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(EngifyColors.textPrimary)

                                DatePicker(
                                    "Reminder time",
                                    selection: $settings.dailyReminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .frame(height: 120)
                            }

                            Divider()
                        }

                        EngifySettingToggleRow(
                            title: "Streak protection reminder",
                            subtitle: "Warn you when a streak is at risk of breaking.",
                            isOn: $settings.streakReminderEnabled
                        )

                        Divider()

                        EngifySettingToggleRow(
                            title: "Weekly progress summary",
                            subtitle: "Get a recap of wins, weak areas, and next steps.",
                            isOn: $settings.weeklySummaryEnabled
                        )
                    }
                } else if settings.notificationPermissionStatus == .granted {
                    Text("Turn on notifications to enable reminders.")
                        .font(.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                }
            }
        }
    }

    private var dictionaryAPISection: some View {
        EngifySettingsSection(
            title: "Dictionary API",
            subtitle: "Change the lookup API here only. Leave it empty to keep the default public dictionary API."
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Lookup API base URL")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    TextField("https://api.dictionaryapi.dev/api/v2/entries/en", text: $settings.dictionaryAPIBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, Spacing.md)
                        .frame(minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(EngifyColors.canvasRaised)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(EngifyColors.border.opacity(0.8), lineWidth: 1)
                        )
                }

                Text("Use a full base URL that ends before the searched word. If the field is blank or invalid, Engify keeps using the first default API.")
                    .font(.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Use Default API") {
                    settings.dictionaryAPIBaseURL = ""
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accentColor)
            }
        }
    }

    private var advancedLearningSection: some View {
        EngifySettingsSection(
            title: "Advanced learning controls",
            subtitle: "Fine-tune the learning experience to your preferences."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                EngifySettingToggleRow(
                    title: "Show definitions by default",
                    subtitle: "Automatically expand word details in the Dictionary tab.",
                    isOn: $settings.showDefinitionsByDefault
                )

                Divider()

                EngifySettingToggleRow(
                    title: "Haptic feedback",
                    subtitle: "Device vibration for interactions (saves battery if disabled).",
                    isOn: $settings.hapticFeedbackEnabled
                )
            }
        }
    }

    private var appPreferencesSection: some View {
        EngifySettingsSection(
            title: "App preferences",
            subtitle: "Control the little interface touches that shape how Engify feels day to day."
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                EngifySettingToggleRow(
                    title: "App Audio / Sounds",
                    subtitle: "Mute interactive sound effects and click chimes.",
                    isOn: $settings.soundEffectsEnabled
                )

                if settings.soundEffectsEnabled {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Sound effect style")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EngifyColors.textPrimary)

                        HStack(spacing: Spacing.sm) {
                            ForEach(SoundEffectStyle.allCases) { style in
                                EngifySettingOptionChip(
                                    title: style.title,
                                    isSelected: settings.soundEffectStyle == style.rawValue
                                ) {
                                    settings.soundEffectStyle = style.rawValue
                                    EngifyFeedback.shared.play(.tabSwitch, settings: settings)
                                }
                            }
                        }

                        Text((SoundEffectStyle(rawValue: settings.soundEffectStyle) ?? .classic).subtitle)
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var accessibilitySection: some View {
        EngifySettingsSection(
            title: "Accessibility",
            subtitle: "Make the app easier to read and less visually intense when needed."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                EngifySettingToggleRow(
                    title: "Reduce motion",
                    subtitle: "Minimize animations and transitions (uses less battery too).",
                    isOn: $settings.reducedMotionEnabled
                )

                Divider()

                EngifySettingToggleRow(
                    title: "High contrast",
                    subtitle: "Increase separation between text, cards, and backgrounds.",
                    isOn: $settings.highContrastEnabled
                )
            }
        }
    }

    private var appearanceSection: some View {
        EngifySettingsSection(
            title: "Appearance",
            subtitle: "Adjust colors and typography to your preference."
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Accent color")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(ThemeManager.Accent.allCases) { accent in
                            Button {
                                theme.accent = accent
                            } label: {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(accent.color)
                                    .frame(height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(theme.accent == accent ? EngifyColors.surface : Color.clear, lineWidth: 2)
                                    )
                                    .overlay(alignment: .bottomTrailing) {
                                        if theme.accent == accent {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(EngifyColors.textInverse)
                                                .padding(6)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Appearance mode")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(ThemeManager.AppearanceMode.allCases) { mode in
                            EngifySettingOptionChip(
                                title: mode.rawValue.capitalized,
                                isSelected: theme.appearance == mode
                            ) {
                                theme.appearance = mode
                            }
                        }
                    }
                }

                EngifySettingSliderRow(
                    title: "Font size",
                    subtitle: "Larger text for longer study sessions.",
                    value: Binding(
                        get: { Double(theme.fontSize) },
                        set: { theme.fontSize = CGFloat($0) }
                    ),
                    range: 14...22,
                    step: 1
                ) { value in
                    "\(Int(value)) pt"
                }
            }
        }
    }

    // MARK: - Helpers

    private var currentSettingsSnapshot: String {
        [
            settings.learningGoal,
            settings.explanationDepth,
            settings.correctionStyle,
            settings.generateExtraExamples.description,
            settings.speechFeedbackEnabled.description,
            settings.transcriptVisible.description,
            settings.speakingSpeed,
            settings.pronunciationModel,
            String(settings.newWordsPerDay),
            String(settings.reviewLimitPerDay),
            settings.dictionaryAPIBaseURL,
            settings.notificationsEnabled.description,
            settings.dailyReminderEnabled.description,
            String(settings.dailyReminderTime.timeIntervalSince1970),
            settings.streakReminderEnabled.description,
            settings.weeklySummaryEnabled.description,
            settings.microphoneEnabled.description,
            settings.voiceHistoryEnabled.description,
            settings.soundEffectsEnabled.description,
            settings.soundEffectStyle,
            settings.hapticFeedbackEnabled.description,
            settings.showDefinitionsByDefault.description,
            settings.showGrammarCorrections.description,
            settings.repeatPronunciation.description,
            settings.difficultyLock.description,
            settings.reducedMotionEnabled.description,
            settings.highContrastEnabled.description,
            theme.accent.rawValue,
            theme.appearance.rawValue,
            String(format: "%.2f", Double(theme.fontSize))
        ]
        .joined(separator: "|")
    }

    private func formatBytes(_ bytes: Int) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }

    private var saveConfirmationBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(EngifyColors.sage)

            VStack(alignment: .leading, spacing: 2) {
                Text("Changes saved")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EngifyColors.textPrimary)

                Text("Your settings were updated successfully.")
                    .font(.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(EngifyColors.sage.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(EngifyColors.sage.opacity(0.22), lineWidth: 1)
        )
    }

    private func showChangesSaved() {
        saveConfirmationTask?.cancel()

        withAnimation {
            showSaveConfirmation = true
        }

        let hideTask = DispatchWorkItem {
            withAnimation {
                showSaveConfirmation = false
            }
        }

        saveConfirmationTask = hideTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: hideTask)
    }

    private func refreshCurrentAppIconSelection() {
        selectedAppIconOption = AppIconOption.current(
            from: UIApplication.shared.alternateIconName
        )
    }

    private func applyAppIcon(_ option: AppIconOption) async {
#if targetEnvironment(simulator)
        showAppIconStatus(
            message: "Home Screen app icon changes are currently unreliable in iOS Simulator. Please test this feature on a physical iPhone or iPad.",
            type: .info
        )
        return
#endif

        guard UIApplication.shared.supportsAlternateIcons else {
            showAppIconStatus(
                message: "This device does not support alternate app icons.",
                type: .error
            )
            return
        }

        let currentAlternateIconName = UIApplication.shared.alternateIconName
        guard currentAlternateIconName != option.alternateIconName else {
            showAppIconPicker = false
            return
        }

        do {
            try await setAlternateAppIconName(option.alternateIconName)
            refreshCurrentAppIconSelection()
            showAppIconPicker = false
            showAppIconStatus(
                message: "App icon changed to \(option.title).",
                type: .success
            )
        } catch {
            showAppIconStatus(
                message: "Engify could not change the app icon: \(error.localizedDescription)",
                type: .error
            )
        }
    }

    private func setAlternateAppIconName(_ name: String?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIApplication.shared.setAlternateIconName(name) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func showAppIconStatus(message: String, type: StatusBanner.BannerType) {
        appIconStatusTask?.cancel()
        appIconStatusMessage = message
        appIconStatusType = type

        let hideTask = DispatchWorkItem {
            withAnimation {
                appIconStatusMessage = nil
            }
        }

        appIconStatusTask = hideTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4, execute: hideTask)
    }

    @State private var showResetConfirmation = false

    private var resetSection: some View {
        EngifySettingsSection(
            title: "Reset",
            subtitle: "Restore all learning settings to their original values."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(EngifyColors.coral)
                            .frame(width: 36, height: 36)
                            .background(EngifyColors.coral.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Reset to defaults")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(EngifyColors.coral)

                            Text("Revert all settings to \"Engify Default\". Notifications and microphone won't change.")
                                .font(.caption)
                                .foregroundStyle(EngifyColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(EngifyColors.textSecondary.opacity(0.5))
                    }
                    .padding(.vertical, Spacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("Engify v1.0 · Made with 💚")
                    .font(.caption2)
                    .foregroundStyle(EngifyColors.textSecondary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Spacing.sm)
            }
        }
        .alert("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all learning settings to the Engify Default preset. This cannot be undone.")
        }
    }

    private var privacySection: some View {
        EngifySettingsSection(
            title: "Privacy",
            subtitle: "Voice and learning history stay on-device unless you add cloud sync."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Store voice history")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EngifyColors.textPrimary)

                        Text("Keep recordings for review and comparison.")
                            .font(.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                    }

                    Spacer()

                    if settings.voiceHistoryStorageUsage > 50_000_000 {  // 50MB
                        Button(action: { showStorageWarning = true }) {
                            Text(formatBytes(settings.voiceHistoryStorageUsage))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(EngifyColors.coral)
                        }
                        .buttonStyle(.plain)
                    }

                    Toggle("", isOn: $settings.voiceHistoryEnabled)
                        .tint(theme.accentColor)
                }
            }
        }
    }

    private var legalSection: some View {
        EngifySettingsSection(
            title: "Legal",
            subtitle: "Keep App Store review-friendly documents available in the app, including account deletion guidance."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                legalLinkRow(
                    title: "Terms & Conditions",
                    subtitle: "Usage rules, account responsibilities, and acceptable use for Engify.",
                    systemImage: "doc.text.fill",
                    document: .termsAndConditions
                )

                legalLinkRow(
                    title: "Privacy Policy",
                    subtitle: "What Engify stores, what stays on-device, and how account data is handled.",
                    systemImage: "hand.raised.fill",
                    document: .privacyPolicy
                )

                legalLinkRow(
                    title: "Account Deletion",
                    subtitle: "How to permanently delete your account and what data is removed.",
                    systemImage: "trash.fill",
                    document: .accountDeletion
                )

                if authManager.isAuthenticated {
                    SecondaryButton(
                        title: authManager.isLoading ? "Deleting..." : "Delete My Account",
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
    }

    private func legalLinkRow(
        title: String,
        subtitle: String,
        systemImage: String,
        document: EngifyLegalDocument
    ) -> some View {
        NavigationLink {
            EngifyLegalDocumentView(document: document)
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(theme.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(EngifyColors.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(EngifyColors.canvasRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(EngifyColors.border.opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private enum AppIconOption: String, CaseIterable, Identifiable {
    case `default`
    case base
    case dark
    case premium
    case tinted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default:
            return "Any Appearance"
        case .base:
            return "Base"
        case .dark:
            return "Dark"
        case .premium:
            return "EngifyBrandLogo"
        case .tinted:
            return "Tinted"
        }
    }

    var subtitle: String {
        switch self {
        case .default:
            return "Default Home Screen icon"
        case .base:
            return "Clean classic icon"
        case .dark:
            return "A deeper, darker icon style"
        case .premium:
            return "Premium signature icon"
        case .tinted:
            return "A lighter, color-forward icon style"
        }
    }

    var badgeText: String? {
        switch self {
        case .premium:
            return "Premium"
        case .default, .base, .dark, .tinted:
            return nil
        }
    }

    var alternateIconName: String? {
        switch self {
        case .default:
            return nil
        case .base:
            return "AppIconBase"
        case .dark:
            return "AppIconDark"
        case .premium:
            return "AppIconPremium"
        case .tinted:
            return "AppIconTinted"
        }
    }

    var previewAssetName: String {
        switch self {
        case .default:
            return "AppIconPreviewDefault"
        case .base:
            return "AppIconPreviewBase"
        case .dark:
            return "AppIconPreviewDark"
        case .premium:
            return "AppIconPreviewPremium"
        case .tinted:
            return "AppIconPreviewTinted"
        }
    }

    static func current(from alternateIconName: String?) -> AppIconOption {
        switch alternateIconName {
        case "AppIconBase":
            return .base
        case "AppIconDark":
            return .dark
        case "AppIconPremium":
            return .premium
        case "AppIconTinted":
            return .tinted
        default:
            return .default
        }
    }
}

private struct AppIconPreview: View {
    let option: AppIconOption
    let size: CGFloat

    var body: some View {
        Image(option.previewAssetName)
            .resizable()
            .scaledToFit()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(EngifyColors.border.opacity(0.82), lineWidth: 1)
        )
    }
}

private struct AppIconPickerSheet: View {
    let selectedOption: AppIconOption
    let onSelect: (AppIconOption) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Choose the Engify Home Screen app icon you want to use.")
                        .font(EngifyTypography.body)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(AppIconOption.allCases) { option in
                        Button {
                            dismiss()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                onSelect(option)
                            }
                        } label: {
                            HStack(spacing: Spacing.md) {
                                AppIconPreview(option: option, size: 58)

                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    HStack(spacing: Spacing.xs) {
                                        Text(option.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(EngifyColors.textPrimary)

                                        if let badgeText = option.badgeText {
                                            Text(badgeText)
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(EngifyColors.warning)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(EngifyColors.warning.opacity(0.14))
                                                .clipShape(Capsule())
                                        }
                                    }

                                    Text(option.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(EngifyColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                Image(systemName: selectedOption == option ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedOption == option ? EngifyColors.accent : EngifyColors.textSecondary.opacity(0.45))
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(selectedOption == option ? EngifyColors.accentLight.opacity(0.72) : EngifyColors.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(selectedOption == option ? EngifyColors.accent.opacity(0.24) : EngifyColors.border.opacity(0.75), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
            .background(EngifyAppBackground())
            .navigationTitle("Home Screen App Icon")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private enum EngifyLegalDocument {
    case termsAndConditions
    case privacyPolicy
    case accountDeletion

    var title: String {
        switch self {
        case .termsAndConditions:
            return "Terms & Conditions"
        case .privacyPolicy:
            return "Privacy Policy"
        case .accountDeletion:
            return "Account Deletion"
        }
    }

    var sections: [(title: String, body: String)] {
        switch self {
        case .termsAndConditions:
            return [
                (
                    "Using Engify",
                    "Engify is a language-learning app designed to help you practice vocabulary, reading, speaking, and study habits. By using the app, you agree to use it lawfully and not attempt to misuse, disrupt, or reverse engineer the service."
                ),
                (
                    "Accounts",
                    "You are responsible for the accuracy of the information you provide when creating an account and for maintaining the confidentiality of your login credentials. You may continue in guest mode, but some features require a registered account."
                ),
                (
                    "Learning Content",
                    "Engify may provide AI-assisted or third-party sourced explanations, examples, lookup results, or reading materials. These materials are provided for educational use and may occasionally contain errors, so you should use your own judgment when relying on them."
                ),
                (
                    "Availability",
                    "We may update, improve, suspend, or remove features at any time to maintain service quality, security, or compliance. We may also limit access to features that require authentication, external services, or supported devices."
                ),
                (
                    "Termination",
                    "You may stop using Engify at any time. If you want your account removed, you can request permanent deletion from inside the app by opening Profile and choosing Delete Account."
                )
            ]
        case .privacyPolicy:
            return [
                (
                    "Information We Store",
                    "If you create an account, Engify stores the basic information needed to operate your profile, including your email address, display name, avatar choice, saved words, and synced learning progress."
                ),
                (
                    "Information That Stays On Device",
                    "App preferences, some learning settings, and optional voice-history storage remain on your device unless a future feature explicitly asks to sync them to the cloud."
                ),
                (
                    "Online Features",
                    "When you use connected features such as authentication, synced progress, dictionary lookup, or online content, Engify may send the minimum data required to the service providers that power those features."
                ),
                (
                    "How We Use Data",
                    "Your data is used to sign you in, personalize your profile, restore your saved learning progress, and support the features you choose to use inside the app."
                ),
                (
                    "Your Choices",
                    "You can use guest mode for limited access, manage settings from the Settings screen, and permanently delete your account from the Profile screen. Deleting your account removes associated synced account data from the app database."
                )
            ]
        case .accountDeletion:
            return [
                (
                    "How To Delete",
                    "Open the profile menu from the top-left corner of the app, choose Profile, then tap Delete Account. You will be asked to confirm before the deletion request is sent."
                ),
                (
                    "What Gets Removed",
                    "Once completed, your Engify account record and the synced data associated with that account, such as profile details, saved words, progress, lesson history, and earned badges, are permanently removed from the database."
                ),
                (
                    "Important Notes",
                    "Account deletion is permanent and cannot be undone. If you only want to stop using the app temporarily, you can sign out instead of deleting your account."
                )
            ]
        }
    }
}

private struct EngifyLegalDocumentView: View {
    let document: EngifyLegalDocument

    var body: some View {
        ZStack {
            EngifyAppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(section.title)
                                    .font(EngifyTypography.headline)
                                    .foregroundStyle(EngifyColors.textPrimary)

                                Text(section.body)
                                    .font(EngifyTypography.body)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let savedWordsManager = SavedWordsManager()
        let gamificationManager = GamificationManager()
        let surveyManager = OnboardingSurveyManager()

        SettingsView()
            .environmentObject(AuthenticationManager(
                savedWordsManager: savedWordsManager,
                gamificationManager: gamificationManager,
                surveyManager: surveyManager
            ))
            .environmentObject(ThemeManager())
            .environmentObject(gamificationManager)
            .environmentObject(LearningSettingsManager())
            .environmentObject(surveyManager)
    }
}
