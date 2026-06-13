import SwiftUI

enum SettingsFocusSection: Hashable {
    case dictionaryAPI
    case imageProviders
    case newsSources
}

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
    private enum ActiveSheet: Identifiable {
        case appIconPicker
        case dictionaryAPI
        case imageProviders
        case newsSources

        var id: String {
            switch self {
            case .appIconPicker:
                return "app_icon_picker"
            case .dictionaryAPI:
                return "dictionary_api"
            case .imageProviders:
                return "image_providers"
            case .newsSources:
                return "news_sources"
            }
        }
    }

    private enum ActiveAlert: Identifiable {
        case storageWarning
        case applyPreset(SettingsPreset)
        case deleteAccount

        var id: String {
            switch self {
            case .storageWarning:
                return "storage_warning"
            case let .applyPreset(preset):
                return "apply_preset_\(preset.id)"
            case .deleteAccount:
                return "delete_account"
            }
        }
    }

    private struct SaveConfirmationOverlayModifier: ViewModifier {
        let isVisible: Bool
        let banner: AnyView

        func body(content: Content) -> some View {
            content
                .overlay(alignment: .top) {
                    if isVisible {
                        banner
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.sm)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1000)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private struct SettingsSheetPresentationModifier: ViewModifier {
        let sheet: ActiveSheet

        @ViewBuilder
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content
                    .presentationDetents(
                        sheet == .appIconPicker ? [.medium, .large] : [.large]
                    )
                    .presentationDragIndicator(.visible)
            } else {
                content
            }
        }
    }

    let initialSection: SettingsFocusSection?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var settings: LearningSettingsManager
    
    @State private var requestingNotificationPermission = false
    @State private var requestingMicrophonePermission = false
    @State private var activeAlert: ActiveAlert?
    @State private var showSaveConfirmation = false
    @State private var saveConfirmationTask: DispatchWorkItem?
    @State private var settingsSnapshot = ""
    @State private var activeSheet: ActiveSheet?
    @State private var selectedAppIconOption = AppIconOption.current(from: nil)
    @State private var appIconStatusMessage: String?
    @State private var appIconStatusType: StatusBanner.BannerType = .success
    @State private var appIconStatusTask: DispatchWorkItem?
    @State private var imageProviderName = ""
    @State private var imageProviderBaseURL = ""
    @State private var imageProviderAPIKey = ""
    @State private var imageProviderAttributionHost = ""
    @State private var imageProviderStatusMessage: String?
    @State private var imageProviderStatusType: StatusBanner.BannerType = .info
    @State private var newsSourceName = ""
    @State private var newsSourceURL = ""
    @State private var newsSourceCategory = "World"
    @State private var newsSourceStatusMessage: String?
    @State private var newsSourceStatusType: StatusBanner.BannerType = .info
    @State private var pendingInitialNavigation: SettingsFocusSection?
    @State private var hasQueuedInitialNavigation = false
    private let betaTag = "Beta"

    init(initialSection: SettingsFocusSection? = nil) {
        self.initialSection = initialSection
    }

    private func queueInitialNavigationIfNeeded() {
        guard let initialSection, !hasQueuedInitialNavigation else { return }
        hasQueuedInitialNavigation = true

        DispatchQueue.main.async {
            pendingInitialNavigation = initialSection
        }
    }

    private func performInitialNavigation(
        to section: SettingsFocusSection,
        using proxy: ScrollViewProxy
    ) {
        // Consume the queued request and then perform the scroll/sheet routing
        // on later main-thread cycles so no state changes happen during layout.
        DispatchQueue.main.async {
            pendingInitialNavigation = nil

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(section, anchor: .top)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    presentInitialSheet(for: section)
                }
            }
        }
    }

    private func presentInitialSheet(for section: SettingsFocusSection) {
        DispatchQueue.main.async {
            switch section {
            case .dictionaryAPI:
                activeSheet = .dictionaryAPI
            case .imageProviders:
                activeSheet = .imageProviders
            case .newsSources:
                activeSheet = .newsSources
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var saveConfirmationOverlayBanner: AnyView {
        AnyView(saveConfirmationBanner)
    }

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            statusSection
                            overviewCard
                            notificationSection
                            speakingSection
                            practiceSection
                            appearanceSection
                            appPreferencesSection
                            learningGoalSection
                            aiTutorSection
                            settingsPresetSection
                            advancedLearningSection
                            accessibilitySection
                            dictionaryAPISection
                                .id(SettingsFocusSection.dictionaryAPI)
                            imageProvidersSection
                                .id(SettingsFocusSection.imageProviders)
                            newsSourcesSection
                                .id(SettingsFocusSection.newsSources)
                            privacySection
                            legalSection
                            creditsSection
                            resetSection
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                    .onChange(of: pendingInitialNavigation) { section in
                        guard let section else { return }
                        performInitialNavigation(to: section, using: proxy)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .modifier(
            SaveConfirmationOverlayModifier(
                isVisible: showSaveConfirmation && activeSheet == nil,
                banner: saveConfirmationOverlayBanner
            )
        )
        .navigationViewStyle(StackNavigationViewStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showSaveConfirmation)
        .onAppear {
            DispatchQueue.main.async {
                settingsSnapshot = currentSettingsSnapshot
                refreshCurrentAppIconSelection()
                queueInitialNavigationIfNeeded()
            }
        }
        .onChange(of: currentSettingsSnapshot) { newSnapshot in
            guard !settingsSnapshot.isEmpty, newSnapshot != settingsSnapshot else { return }
            handleSettingsSnapshotChange(newSnapshot)
        }
        .onDisappear {
            saveConfirmationTask?.cancel()
            appIconStatusTask?.cancel()
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .storageWarning:
                return Alert(
                    title: Text("Storage Warning"),
                    message: Text("Voice history is using \(formatBytes(settings.voiceHistoryStorageUsage)). Delete to free space?"),
                    primaryButton: .destructive(Text("Delete")) {
                        settings.voiceHistoryEnabled = false
                    },
                    secondaryButton: .cancel()
                )
            case let .applyPreset(preset):
                return Alert(
                    title: Text("Apply Preset"),
                    message: Text("This will replace your current settings with the \"\(preset.title)\" preset. Notification and microphone settings won't change."),
                    primaryButton: .destructive(Text("Apply")) {
                        settings.applyPreset(preset)
                    },
                    secondaryButton: .cancel()
                )
            case .deleteAccount:
                return Alert(
                    title: Text("Delete Account?"),
                    message: Text("This permanently removes your Engify account and associated synced learning data. This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            let didDelete = await authManager.deleteAccount()
                            if didDelete {
                                dismiss()
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .appIconPicker:
                    AppIconPickerSheet(
                        selectedOption: selectedAppIconOption,
                        onSelect: { option in
                            Task { @MainActor in
                                await applyAppIcon(option)
                            }
                        }
                    )

                case .dictionaryAPI:
                    DictionaryAPIManagementSheet()
                        .environmentObject(theme)
                        .environmentObject(settings)
                        .modifier(
                            SaveConfirmationOverlayModifier(
                                isVisible: showSaveConfirmation,
                                banner: saveConfirmationOverlayBanner
                            )
                        )

                case .imageProviders:
                    ImageProviderManagementSheet(
                        providerName: $imageProviderName,
                        providerBaseURL: $imageProviderBaseURL,
                        providerAPIKey: $imageProviderAPIKey,
                        providerAttributionHost: $imageProviderAttributionHost,
                        statusMessage: $imageProviderStatusMessage,
                        statusType: $imageProviderStatusType,
                        onAddProvider: addCustomImageProvider
                    )
                    .environmentObject(theme)
                    .environmentObject(settings)
                    .modifier(
                        SaveConfirmationOverlayModifier(
                            isVisible: showSaveConfirmation,
                            banner: saveConfirmationOverlayBanner
                        )
                    )

                case .newsSources:
                    NewsSourcesManagementSheet(
                        sourceName: $newsSourceName,
                        sourceURL: $newsSourceURL,
                        sourceCategory: $newsSourceCategory,
                        statusMessage: $newsSourceStatusMessage,
                        statusType: $newsSourceStatusType,
                        onAddSource: addCustomNewsSource
                    )
                    .environmentObject(theme)
                    .environmentObject(settings)
                    .modifier(
                        SaveConfirmationOverlayModifier(
                            isVisible: showSaveConfirmation,
                            banner: saveConfirmationOverlayBanner
                        )
                    )
                }
            }
            .modifier(SettingsSheetPresentationModifier(sheet: sheet))
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
                    activeSheet = .appIconPicker
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
                        activeSheet = .appIconPicker
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
                            activeAlert = .applyPreset(preset)
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

                Text("Turn the toggle off to stop microphone-based features in Engify. To revoke device microphone permission entirely, open iPhone Settings.")
                    .font(.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    openSystemSettings()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "gearshape.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Open iPhone Settings")
                            .font(EngifyTypography.bodyStrong)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: 50)
                    .background(theme.accentColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

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

                Text("Turn the toggle off to stop reminders in Engify. To fully disable iPhone notification permission for Engify, open iPhone Settings.")
                    .font(.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    openSystemSettings()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "gearshape.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Open iPhone Settings")
                            .font(EngifyTypography.bodyStrong)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: 50)
                    .background(theme.accentColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

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

                        Divider()

                        EngifySettingToggleRow(
                            title: "App update alerts",
                            subtitle: "Notify you when a newer Engify version is available on the App Store.",
                            isOn: $settings.appUpdateNotificationsEnabled
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
            subtitle: "See the current endpoint at a glance, then open a pull-up panel to inspect or change it."
        ) {
            Button {
                activeSheet = .dictionaryAPI
            } label: {
                settingsSummaryRow(
                    title: "Dictionary lookup endpoint",
                    value: dictionaryAPIStatusTitle,
                    detail: dictionaryAPIDetailText,
                    systemImage: "book.pages.fill",
                    badgeText: settings.dictionaryAPIBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Default" : "Custom"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var newsSourcesSection: some View {
        EngifySettingsSection(
            title: "News sources",
            subtitle: "See your feed setup quickly, then open a pull-up panel to manage sources and URLs."
        ) {
            Button {
                activeSheet = .newsSources
            } label: {
                settingsSummaryRow(
                    title: "News feed manager",
                    value: "\(NewsFeedSource.builtInSources.count) built-in • \(settings.customNewsSources.count) custom",
                    detail: newsSourcesDetailText,
                    systemImage: "newspaper.fill",
                    badgeText: settings.customNewsSources.isEmpty ? "Built-in only" : "Custom enabled"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var imageProvidersSection: some View {
        EngifySettingsSection(
            title: "Image providers",
            subtitle: "Manage API keys for image search services like Pexels, Unsplash, Pixabay, and any custom provider."
        ) {
            Button {
                activeSheet = .imageProviders
            } label: {
                settingsSummaryRow(
                    title: "Image API manager",
                    value: imageProvidersStatusTitle,
                    detail: imageProvidersDetailText,
                    systemImage: "photo.stack.fill",
                    badgeText: activeImageProviderBadgeText
                )
            }
            .buttonStyle(.plain)
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
            settings.imageAPIProviders.map { "\($0.id)|\($0.baseURL)|\($0.apiKey)|\($0.isEnabled)" }.joined(separator: ","),
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
            settings.customNewsSources.map { "\($0.name)|\($0.urlString)|\($0.category)" }.joined(separator: ","),
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
        StatusBanner(
            message: "Changes saved. Your settings were updated successfully.",
            type: .success
        )
    }

    private func showChangesSaved() {
        saveConfirmationTask?.cancel()

        guard !showSaveConfirmation else {
            scheduleSaveConfirmationHide()
            return
        }

        withAnimation {
            showSaveConfirmation = true
        }

        scheduleSaveConfirmationHide()
    }

    private func scheduleSaveConfirmationHide() {
        let hideTask = DispatchWorkItem {
            withAnimation {
                showSaveConfirmation = false
            }
        }

        saveConfirmationTask = hideTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: hideTask)
    }

    private func handleSettingsSnapshotChange(_ newSnapshot: String) {
        DispatchQueue.main.async {
            guard !settingsSnapshot.isEmpty, newSnapshot != settingsSnapshot else { return }
            settingsSnapshot = newSnapshot
            showChangesSaved()
        }
    }

    private var newsCategoryOptions: [String] {
        ["Learning", "World", "Space", "Science", "Technology", "Sports", "General"]
    }

    private var dictionaryAPIStatusTitle: String {
        settings.dictionaryAPIBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Using Engify default API" : "Using custom dictionary API"
    }

    private var dictionaryAPIDetailText: String {
        let trimmed = settings.dictionaryAPIBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Tap to review the default endpoint or replace it with your own base URL." : trimmed
    }

    private var newsSourcesDetailText: String {
        if let firstCustom = settings.customNewsSources.first {
            return "Custom feeds are active, including \(firstCustom.name). Tap to review full URLs, remove feeds, or add more."
        }

        return "Engify is currently using built-in feeds only. Tap to review them or add your own RSS/Atom sources."
    }

    private var imageProvidersStatusTitle: String {
        let enabledProviders = settings.imageAPIProviders.filter(\.isEnabled)
        let configuredProviders = settings.imageAPIProviders.filter { !$0.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return "\(enabledProviders.count) enabled • \(configuredProviders.count) keyed"
    }

    private var imageProvidersDetailText: String {
        if let firstConfigured = settings.imageAPIProviders.first(where: { !$0.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return "\(firstConfigured.name) is configured. Tap to update keys, switch providers, or add more image services."
        }

        return "No image API keys saved yet. Tap to add keys for Pexels, Unsplash, Pixabay, or your own provider."
    }

    private var activeImageProviderBadgeText: String {
        let activeCount = settings.imageAPIProviders.filter(\.isEnabled).count
        return activeCount == 0 ? "Disabled" : "\(activeCount) active"
    }

    private func addCustomNewsSource() {
        let result = settings.addCustomNewsSource(
            name: newsSourceName,
            urlString: newsSourceURL,
            category: newsSourceCategory
        )

        switch result {
        case let .success(message):
            newsSourceName = ""
            newsSourceURL = ""
            newsSourceCategory = "World"
            showNewsSourceStatus(message: message, type: .success)
        case let .failure(message):
            showNewsSourceStatus(message: message, type: .error)
        }
    }

    private func addCustomImageProvider() {
        let result = settings.addCustomImageAPIProvider(
            name: imageProviderName,
            baseURL: imageProviderBaseURL,
            apiKey: imageProviderAPIKey,
            attributionHost: imageProviderAttributionHost
        )

        switch result {
        case let .success(message):
            imageProviderName = ""
            imageProviderBaseURL = ""
            imageProviderAPIKey = ""
            imageProviderAttributionHost = ""
            showImageProviderStatus(message: message, type: .success)
        case let .failure(message):
            showImageProviderStatus(message: message, type: .error)
        }
    }

    private func showNewsSourceStatus(message: String, type: StatusBanner.BannerType) {
        withAnimation(.easeInOut(duration: 0.2)) {
            newsSourceStatusMessage = message
            newsSourceStatusType = type
        }
    }

    private func showImageProviderStatus(message: String, type: StatusBanner.BannerType) {
        withAnimation(.easeInOut(duration: 0.2)) {
            imageProviderStatusMessage = message
            imageProviderStatusType = type
        }
    }

    @ViewBuilder
    private func settingsSummaryRow(
        title: String,
        value: String,
        detail: String,
        systemImage: String,
        badgeText: String
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.accentColor)
                .frame(width: 40, height: 40)
                .background(theme.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(badgeText)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.accentColor)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(theme.accentColor.opacity(0.10))
                        .clipShape(Capsule())
                }

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EngifyColors.textPrimary)

                Text(detail)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(EngifyColors.textSecondary.opacity(0.72))
                .padding(.top, 4)
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func externalLinkRow(
        title: String,
        subtitle: String,
        systemImage: String,
        urlString: String,
        hostLabel: String
    ) -> some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                        .frame(width: 40, height: 40)
                        .background(theme.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(title)
                            .font(EngifyTypography.bodyStrong)
                            .foregroundStyle(EngifyColors.textPrimary)

                        Text(subtitle)
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(hostLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.accentColor)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.accentColor)
                        .padding(.top, 4)
                }
                .padding(.vertical, Spacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func newsSourceRow(
        title: String,
        category: String,
        urlString: String,
        isCustom: Bool,
        onRemove: (() -> Void)?
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(category)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(theme.accentColor.opacity(0.10))
                        .clipShape(Capsule())

                    if isCustom {
                        EngifySettingsBadge(text: "Custom")
                    }
                }

                Text(urlString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(EngifyColors.textSecondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.coral)
                        .frame(width: 36, height: 36)
                        .background(EngifyColors.coral.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
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
            activeSheet = nil
            return
        }

        do {
            try await setAlternateAppIconName(option.alternateIconName)
            refreshCurrentAppIconSelection()
            activeSheet = nil
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
                        Button(action: { activeAlert = .storageWarning }) {
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
                            activeAlert = .deleteAccount
                        },
                        isDisabled: authManager.isLoading,
                        tint: EngifyColors.coral
                    )
                }
            }
        }
    }

    private var creditsSection: some View {
        EngifySettingsSection(
            title: "Credits",
            subtitle: "Support the creator, follow development updates, or open the full profile hub."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                externalLinkRow(
                    title: "Support on PayPal",
                    subtitle: "Help support Engify development.",
                    systemImage: "heart.text.square.fill",
                    urlString: "https://www.paypal.com/paypalme/dominhduy09",
                    hostLabel: "paypal.com/paypalme/dominhduy09"
                )

                Divider()

                externalLinkRow(
                    title: "GitHub",
                    subtitle: "See projects and code updates from dominhduy09.",
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    urlString: "https://github.com/dominhduy09",
                    hostLabel: "github.com/dominhduy09"
                )

                Divider()

                externalLinkRow(
                    title: "Bio Link",
                    subtitle: "Open the full profile hub for more links.",
                    systemImage: "link.circle.fill",
                    urlString: "https://bio.link/dmduy",
                    hostLabel: "bio.link/dmduy"
                )
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

private struct DictionaryAPIManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var settings: LearningSettingsManager
    @State private var draftURL = ""

    private let builtInSources: [(title: String, role: String, url: String, isOverrideable: Bool)] = [
        (
            title: "Supabase Vocabulary",
            role: "Primary word source when Engify has a matching curated entry.",
            url: "Supabase table: vocabulary_words",
            isOverrideable: false
        ),
        (
            title: "DictionaryAPI.dev",
            role: "Default public lookup API used when a curated entry is not available.",
            url: "https://api.dictionaryapi.dev/api/v2/entries/en",
            isOverrideable: true
        ),
        (
            title: "Datamuse Suggestions",
            role: "Built-in suggestion source for search hints and spelling help.",
            url: "https://api.datamuse.com/sug",
            isOverrideable: false
        )
    ]

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        EngifyCard(tint: theme.accentColor) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Dictionary lookup API")
                                    .font(EngifyTypography.headline)
                                    .foregroundStyle(EngifyColors.textPrimary)

                                Text("Use the default public dictionary endpoint or provide your own base URL that stops before the searched word.")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Built-in sources")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(EngifyColors.textPrimary)

                                ForEach(Array(builtInSources.enumerated()), id: \.offset) { index, source in
                                    dictionarySourceRow(
                                        title: source.title,
                                        role: source.role,
                                        url: source.url,
                                        badgeText: source.isOverrideable ? "Overrideable" : "Built-in"
                                    )

                                    if index < builtInSources.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }

                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Custom lookup override")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(EngifyColors.textPrimary)

                                TextField("https://api.dictionaryapi.dev/api/v2/entries/en", text: $draftURL)
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

                                Text(draftURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Currently using the built-in DictionaryAPI.dev lookup URL. This override does not replace Supabase or Datamuse." : "Changes save automatically when you edit this field. The override only affects the public lookup API.")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: Spacing.md) {
                                    SecondaryButton(title: "Use Default", systemImage: "arrow.counterclockwise", action: {
                                        draftURL = ""
                                        settings.dictionaryAPIBaseURL = ""
                                    })

                                    PrimaryButton(title: "Done", systemImage: "checkmark.circle.fill", action: {
                                        settings.dictionaryAPIBaseURL = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                        dismiss()
                                    })
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Dictionary API")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            draftURL = settings.dictionaryAPIBaseURL
        }
        .onChange(of: draftURL) { value in
            settings.dictionaryAPIBaseURL = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    @ViewBuilder
    private func dictionarySourceRow(
        title: String,
        role: String,
        url: String,
        badgeText: String
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(badgeText)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.accentColor)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(theme.accentColor.opacity(0.10))
                        .clipShape(Capsule())
                }

                Text(role)
                    .font(EngifyTypography.caption)
                    .foregroundStyle(EngifyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(url)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(EngifyColors.textSecondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct NewsSourcesManagementSheet: View {
    @Binding var sourceName: String
    @Binding var sourceURL: String
    @Binding var sourceCategory: String
    @Binding var statusMessage: String?
    @Binding var statusType: StatusBanner.BannerType
    let onAddSource: () -> Void

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var settings: LearningSettingsManager

    private var newsCategoryOptions: [String] {
        ["Learning", "World", "Space", "Science", "Technology", "Sports", "General"]
    }

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        if let statusMessage, !statusMessage.isEmpty {
                            StatusBanner(message: statusMessage, type: statusType)
                        }

                        EngifyCard(tint: theme.accentColor) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("News source manager")
                                    .font(EngifyTypography.headline)
                                    .foregroundStyle(EngifyColors.textPrimary)

                                Text("Built-in feeds stay available automatically. Add your own public RSS or Atom feeds below when you want more sources.")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Built-in feeds")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(EngifyColors.textPrimary)

                                ForEach(Array(NewsFeedSource.builtInSources.enumerated()), id: \.offset) { index, source in
                                    newsSourceRow(
                                        title: source.publisherName,
                                        category: source.defaultCategory,
                                        urlString: source.urlString,
                                        isCustom: false,
                                        onRemove: nil
                                    )

                                    if index < NewsFeedSource.builtInSources.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }

                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack {
                                    Text("Your custom feeds")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(EngifyColors.textPrimary)

                                    Spacer(minLength: 0)

                                    Text("\(settings.customNewsSources.count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(theme.accentColor)
                                }

                                if settings.customNewsSources.isEmpty {
                                    Text("No custom sources yet. Add one below and it will be used on the next news refresh.")
                                        .font(EngifyTypography.caption)
                                        .foregroundStyle(EngifyColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    ForEach(Array(settings.customNewsSources.enumerated()), id: \.element.id) { index, source in
                                        newsSourceRow(
                                            title: source.name,
                                            category: source.category,
                                            urlString: source.urlString,
                                            isCustom: true,
                                            onRemove: {
                                                settings.removeCustomNewsSource(id: source.id)
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    statusMessage = "Removed \(source.name) from your custom sources."
                                                    statusType = .info
                                                }
                                            }
                                        )

                                        if index < settings.customNewsSources.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Add a feed")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(EngifyColors.textPrimary)

                                TextField("Source name", text: $sourceName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
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

                                TextField("https://example.com/feed.xml", text: $sourceURL)
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

                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("Category")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(EngifyColors.textPrimary)

                                    TextField("Type any category name", text: $sourceCategory)
                                        .textInputAutocapitalization(.words)
                                        .autocorrectionDisabled()
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

                                    WrapChipsView(items: newsCategoryOptions) { item in
                                        EngifySettingOptionChip(
                                            title: item,
                                            isSelected: sourceCategory.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(item) == .orderedSame
                                        ) {
                                            sourceCategory = item
                                        }
                                    }
                                }

                                PrimaryButton(
                                    title: "Add Custom Source",
                                    systemImage: "plus.circle.fill",
                                    action: onAddSource
                                )

                                Text("Use a public RSS or Atom feed URL. Engify will try to parse it the same way it parses the built-in feeds.")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("News Sources")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private func newsSourceRow(
        title: String,
        category: String,
        urlString: String,
        isCustom: Bool,
        onRemove: (() -> Void)?
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(EngifyTypography.bodyStrong)
                        .foregroundStyle(EngifyColors.textPrimary)

                    Text(category)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(theme.accentColor.opacity(0.10))
                        .clipShape(Capsule())

                    if isCustom {
                        EngifySettingsBadge(text: "Custom")
                    }
                }

                Text(urlString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(EngifyColors.textSecondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EngifyColors.coral)
                        .frame(width: 36, height: 36)
                        .background(EngifyColors.coral.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ImageProviderManagementSheet: View {
    @Binding var providerName: String
    @Binding var providerBaseURL: String
    @Binding var providerAPIKey: String
    @Binding var providerAttributionHost: String
    @Binding var statusMessage: String?
    @Binding var statusType: StatusBanner.BannerType
    let onAddProvider: () -> Void

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var settings: LearningSettingsManager

    private var builtInProviders: [ImageAPIProviderConfig] {
        settings.imageAPIProviders.filter(\.isBuiltIn)
    }

    private var customProviders: [ImageAPIProviderConfig] {
        settings.imageAPIProviders.filter { !$0.isBuiltIn }
    }

    var body: some View {
        NavigationView {
            ZStack {
                EngifyAppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        if let statusMessage, !statusMessage.isEmpty {
                            StatusBanner(message: statusMessage, type: statusType)
                        }

                        EngifyCard(tint: theme.accentColor) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Image provider manager")
                                    .font(EngifyTypography.headline)
                                    .foregroundStyle(EngifyColors.textPrimary)

                                Text("Manage API keys for Pexels, Unsplash, Pixabay, and any custom image search provider you want Engify to support.")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Built-in providers")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(EngifyColors.textPrimary)

                                ForEach(Array(builtInProviders.enumerated()), id: \.element.id) { index, provider in
                                    imageProviderRow(provider)

                                    if index < builtInProviders.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }

                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack {
                                    Text("Custom providers")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(EngifyColors.textPrimary)

                                    Spacer(minLength: 0)

                                    Text("\(customProviders.count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(theme.accentColor)
                                }

                                if customProviders.isEmpty {
                                    Text("No custom image providers yet. Add one below if you want another service besides the built-in options.")
                                        .font(EngifyTypography.caption)
                                        .foregroundStyle(EngifyColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    ForEach(Array(customProviders.enumerated()), id: \.element.id) { index, provider in
                                        imageProviderRow(provider)

                                        if index < customProviders.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        EngifyCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Add a custom image provider")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(EngifyColors.textPrimary)

                                TextField("Provider name", text: $providerName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
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

                                TextField("https://example.com/search", text: $providerBaseURL)
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

                                SecureField("API key", text: $providerAPIKey)
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

                                TextField("Attribution host (optional)", text: $providerAttributionHost)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
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

                                PrimaryButton(
                                    title: "Add Image Provider",
                                    systemImage: "plus.circle.fill",
                                    action: onAddProvider
                                )

                                Text("Engify stores your image provider configuration locally so you can switch services without editing code.")
                                    .font(EngifyTypography.caption)
                                    .foregroundStyle(EngifyColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Image Providers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private func imageProviderRow(_ provider: ImageAPIProviderConfig) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Text(provider.name)
                            .font(EngifyTypography.bodyStrong)
                            .foregroundStyle(EngifyColors.textPrimary)

                        EngifySettingsBadge(text: provider.isBuiltIn ? "Built-in" : "Custom")

                        if provider.isEnabled {
                            Text("Enabled")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(theme.accentColor)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 4)
                                .background(theme.accentColor.opacity(0.10))
                                .clipShape(Capsule())
                        }
                    }

                    Text(provider.baseURL)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(EngifyColors.textSecondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)

                    if !provider.attributionHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Attribution: \(provider.attributionHost)")
                            .font(EngifyTypography.caption)
                            .foregroundStyle(EngifyColors.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                Toggle(
                    "",
                    isOn: Binding(
                        get: { provider.isEnabled },
                        set: { settings.updateImageAPIProvider(id: provider.id, isEnabled: $0) }
                    )
                )
                .labelsHidden()
                .tint(theme.accentColor)
            }

            SecureField(
                provider.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Paste your API key" : "API key saved",
                text: Binding(
                    get: { provider.apiKey },
                    set: { settings.updateImageAPIProvider(id: provider.id, apiKey: $0) }
                )
            )
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

            if !provider.isBuiltIn {
                Button(role: .destructive) {
                    settings.removeCustomImageAPIProvider(id: provider.id)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        statusMessage = "Removed \(provider.name) from your image providers."
                        statusType = .info
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "trash")
                        Text("Remove Provider")
                    }
                    .font(EngifyTypography.caption.weight(.semibold))
                    .foregroundStyle(EngifyColors.coral)
                }
                .buttonStyle(.plain)
            }
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
