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
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var settings: LearningSettingsManager
    
    @State private var requestingNotificationPermission = false
    @State private var requestingMicrophonePermission = false
    @State private var showStorageWarning = false

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        overviewCard
                        learningGoalSection
                        aiTutorSection
                        speakingSection
                        practiceSection
                        notificationSection
                        advancedLearningSection
                        accessibilitySection
                        appearanceSection
                        privacySection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Storage Warning", isPresented: $showStorageWarning) {
            Button("Delete", role: .destructive) {
                settings.voiceHistoryEnabled = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Voice history is using \(formatBytes(settings.voiceHistoryStorageUsage)). Delete to free space?")
        }
    }

    private var overviewCard: some View {
        EngifyCard(tint: theme.accentColor) {
            HStack(alignment: .center, spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "slider.horizontal.3")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(theme.accentColor)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Learning preferences")
                        .font(.headline)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text("Customize how Engify teaches, corrects, and motivates you.")
                        .font(.subheadline)
                        .foregroundStyle(EngifyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.accentColor)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.white)
                    )
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

                    if settings.microphonePermissionStatus == .denied {
                        Button("Request") {
                            requestingMicrophonePermission = true
                            Task {
                                let granted = await settings.requestMicrophonePermission()
                                requestingMicrophonePermission = false
                            }
                        }
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

                    if settings.notificationPermissionStatus == .denied {
                        Button("Request") {
                            requestingNotificationPermission = true
                            Task {
                                let granted = await settings.requestNotificationPermission()
                                requestingNotificationPermission = false
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EngifyColors.coral)
                    }
                }

                if settings.notificationPermissionStatus == .granted {
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
                }
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
                    title: "Sound effects",
                    subtitle: "Play sounds for correct/incorrect answers and achievements.",
                    isOn: $settings.soundEffectsEnabled
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
                                            .stroke(theme.accent == accent ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                    .overlay(alignment: .bottomTrailing) {
                                        if theme.accent == accent {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.white)
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

    private func formatBytes(_ bytes: Int) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager())
            .environmentObject(LearningSettingsManager())
    }
}
