import Combine
import SwiftUI
import Foundation
import AVFoundation
import UserNotifications

/// Centralized, production-grade settings manager for all learning preferences.
///
/// WHAT IT DOES:
/// - Manages all learning-related settings: goals, AI tutor, speaking, review, notifications, accessibility.
/// - Validates all values on load; resets to defaults if corrupted.
/// - Checks system permissions before enabling permission-gated features.
/// - Logs all setting changes for analytics.
/// - Persists to UserDefaults with error recovery.
///
/// WHEN IT SHOWS:
/// - Injected as @EnvironmentObject from EngifyApp.
/// - SettingsView reads/writes via bindings.
/// - Other views read settings to control behavior (speaking speed, correction style, etc.).
///
/// HOW IT WORKS:
/// - Init loads all values from UserDefaults with fallbacks.
/// - Each @Published property uses didSet to validate and save.
/// - Permission-gated toggles (notifications, microphone) check system status before enabling.
/// - Failed writes are logged but don't crash the app.
@MainActor
final class LearningSettingsManager: ObservableObject {
    // MARK: - Learning Profile
    
    @Published var learningGoal: String {
        didSet { saveIfValid("learning_goal", learningGoal) { Self.validLearningGoals.contains($0) }; analyzeGoalChange() }
    }
    
    // MARK: - AI Tutor
    
    @Published var explanationDepth: String {
        didSet { saveIfValid("explanation_depth", explanationDepth) { Self.validDepths.contains($0) } }
    }
    
    @Published var correctionStyle: String {
        didSet { saveIfValid("correction_style", correctionStyle) { Self.validStyles.contains($0) } }
    }
    
    @Published var generateExtraExamples: Bool {
        didSet { save("generate_examples", generateExtraExamples) }
    }
    
    // MARK: - Speaking Practice
    
    @Published var speechFeedbackEnabled: Bool {
        didSet { save("speech_feedback", speechFeedbackEnabled) }
    }
    
    @Published var transcriptVisible: Bool {
        didSet { save("transcript_visible", transcriptVisible) }
    }
    
    @Published var speakingSpeed: String {
        didSet { saveIfValid("speaking_speed", speakingSpeed) { Self.validSpeeds.contains($0) } }
    }
    
    @Published var pronunciationModel: String {
        didSet { saveIfValid("pronunciation_model", pronunciationModel) { Self.validModels.contains($0) } }
    }
    
    // MARK: - Practice Cadence
    
    @Published var newWordsPerDay: Int {
        didSet { saveIfValid("new_words_per_day", newWordsPerDay) { $0 >= 3 && $0 <= 20 } }
    }
    
    @Published var reviewLimitPerDay: Int {
        didSet { saveIfValid("review_limit_per_day", reviewLimitPerDay) { $0 >= 5 && $0 <= 40 } }
    }

    @Published var dictionaryAPIBaseURL: String {
        didSet {
            let trimmed = dictionaryAPIBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            save("dictionary_api_base_url", trimmed)
        }
    }
    
    // MARK: - Notifications
    
    @Published var notificationsEnabled: Bool {
        didSet { 
            guard notificationsEnabled != oldValue else { return }
            save("notifications_enabled", notificationsEnabled)
            Task {
                await updateNotificationPermission()
                await syncNotificationSettings()
            }
        }
    }
    
    @Published var dailyReminderEnabled: Bool {
        didSet { 
            guard dailyReminderEnabled != oldValue else { return }
            save("daily_reminder", dailyReminderEnabled)
            Task { await syncNotificationSettings() }
        }
    }
    
    @Published var dailyReminderTime: Date {
        didSet { 
            guard dailyReminderTime != oldValue else { return }
            save("daily_reminder_time", dailyReminderTime.timeIntervalSince1970)
            Task { await syncNotificationSettings() }
        }
    }
    
    @Published var streakReminderEnabled: Bool {
        didSet {
            guard streakReminderEnabled != oldValue else { return }
            save("streak_reminder", streakReminderEnabled)
            Task { await syncNotificationSettings() }
        }
    }
    
    @Published var weeklySummaryEnabled: Bool {
        didSet {
            guard weeklySummaryEnabled != oldValue else { return }
            save("weekly_summary", weeklySummaryEnabled)
            Task { await syncNotificationSettings() }
        }
    }
    
    // MARK: - Microphone & Voice
    
    @Published var microphoneEnabled: Bool {
        didSet { 
            guard microphoneEnabled != oldValue else { return }
            save("microphone_enabled", microphoneEnabled)
            Task {
                if microphoneEnabled && microphonePermissionStatus != .granted {
                    let granted = await requestMicrophonePermission()
                    if !granted {
                        await MainActor.run {
                            self.microphoneEnabled = false
                        }
                    }
                }
                await updateMicrophonePermission()
            }
        }
    }
    
    @Published var voiceHistoryEnabled: Bool {
        didSet { 
            if !voiceHistoryEnabled {
                // Schedule cleanup of stored voice files
                deleteVoiceHistory()
            }
            save("voice_history_enabled", voiceHistoryEnabled)
        }
    }
    
    @Published var soundEffectsEnabled: Bool {
        didSet { save("sound_effects_enabled", soundEffectsEnabled) }
    }

    @Published var soundEffectStyle: String {
        didSet { saveIfValid("sound_effect_style", soundEffectStyle) { Self.validSoundStyles.contains($0) } }
    }
    
    @Published var hapticFeedbackEnabled: Bool {
        didSet { save("haptic_feedback_enabled", hapticFeedbackEnabled) }
    }
    
    // MARK: - Advanced Learning
    
    @Published var showDefinitionsByDefault: Bool {
        didSet { save("show_definitions_default", showDefinitionsByDefault) }
    }
    
    @Published var showGrammarCorrections: Bool {
        didSet { save("show_grammar_corrections", showGrammarCorrections) }
    }
    
    @Published var repeatPronunciation: Bool {
        didSet { save("repeat_pronunciation", repeatPronunciation) }
    }
    
    @Published var difficultyLock: Bool {
        didSet { save("difficulty_lock", difficultyLock) }
    }
    
    // MARK: - Accessibility
    
    @Published var reducedMotionEnabled: Bool {
        didSet { save("reduced_motion", reducedMotionEnabled) }
    }
    
    @Published var highContrastEnabled: Bool {
        didSet { save("high_contrast", highContrastEnabled) }
    }
    
    // MARK: - Privacy
    
    @Published var voiceHistoryStorageUsage: Int = 0
    
    // MARK: - Permission Status (Read-Only)
    
    @Published private(set) var notificationPermissionStatus: PermissionStatus = .notRequested
    @Published private(set) var microphonePermissionStatus: PermissionStatus = .notRequested
    
    // MARK: - Active Preset Tracking
    
    @Published var activePreset: SettingsPreset {
        didSet { save("active_preset", activePreset.rawValue) }
    }
    
    // MARK: - Constants
    
    private static let validLearningGoals = ["daily", "travel", "work", "study", "exam"]
    private static let validDepths = ["simple", "balanced", "detailed"]
    private static let validStyles = ["gentle", "balanced", "strict"]
    private static let validSpeeds = ["slow", "normal", "fast"]
    private static let validModels = ["us_english", "uk_english", "australian"]
    private static let validSoundStyles = SoundEffectStyle.allCases.map(\.rawValue)
    
    private enum Keys {
        static let prefix = "engify.settings."
    }
    
    // MARK: - Initialization
    
    init() {
        // Load all settings with validation and fallbacks
        self.learningGoal = Self.loadValidated("learning_goal", default: "daily") { Self.validLearningGoals.contains($0) }
        self.explanationDepth = Self.loadValidated("explanation_depth", default: "balanced") { Self.validDepths.contains($0) }
        self.correctionStyle = Self.loadValidated("correction_style", default: "gentle") { Self.validStyles.contains($0) }
        self.generateExtraExamples = Self.loadBool("generate_examples", default: true)
        
        self.speechFeedbackEnabled = Self.loadBool("speech_feedback", default: true)
        self.transcriptVisible = Self.loadBool("transcript_visible", default: true)
        self.speakingSpeed = Self.loadValidated("speaking_speed", default: "normal") { Self.validSpeeds.contains($0) }
        self.pronunciationModel = Self.loadValidated("pronunciation_model", default: "us_english") { Self.validModels.contains($0) }
        
        self.newWordsPerDay = Self.loadValidated("new_words_per_day", default: 8) { $0 >= 3 && $0 <= 20 }
        self.reviewLimitPerDay = Self.loadValidated("review_limit_per_day", default: 15) { $0 >= 5 && $0 <= 40 }
        self.dictionaryAPIBaseURL = Self.loadString("dictionary_api_base_url", default: "")
        
        self.notificationsEnabled = Self.loadBool("notifications_enabled", default: true)
        self.dailyReminderEnabled = Self.loadBool("daily_reminder", default: true)
        self.dailyReminderTime = Self.loadDate("daily_reminder_time", default: Self.defaultReminderTime())
        self.streakReminderEnabled = Self.loadBool("streak_reminder", default: true)
        self.weeklySummaryEnabled = Self.loadBool("weekly_summary", default: true)
        
        self.microphoneEnabled = Self.loadBool("microphone_enabled", default: true)
        self.voiceHistoryEnabled = Self.loadBool("voice_history_enabled", default: true)
        self.soundEffectsEnabled = Self.loadBool("sound_effects_enabled", default: true)
        self.soundEffectStyle = Self.loadValidated("sound_effect_style", default: SoundEffectStyle.classic.rawValue) { Self.validSoundStyles.contains($0) }
        self.hapticFeedbackEnabled = Self.loadBool("haptic_feedback_enabled", default: true)
        
        self.showDefinitionsByDefault = Self.loadBool("show_definitions_default", default: false)
        self.showGrammarCorrections = Self.loadBool("show_grammar_corrections", default: true)
        self.repeatPronunciation = Self.loadBool("repeat_pronunciation", default: false)
        self.difficultyLock = Self.loadBool("difficulty_lock", default: false)
        
        self.reducedMotionEnabled = Self.loadBool("reduced_motion", default: false)
        self.highContrastEnabled = Self.loadBool("high_contrast", default: false)
        
        let presetRaw = Self.loadValidated("active_preset", default: "default") { SettingsPreset.allCases.map(\.rawValue).contains($0) }
        self.activePreset = SettingsPreset(rawValue: presetRaw) ?? .default
        
        // Check permissions asynchronously
        Task {
            await checkPermissions()
            await calculateVoiceHistoryStorage()
        }
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.notificationPermissionStatus = granted ? .granted : .denied
                if !granted {
                    self.notificationsEnabled = false
                    self.dailyReminderEnabled = false
                }
            }
            await syncNotificationSettings()
            return granted
        } catch {
            logError("Notification permission request failed", error)
            await MainActor.run {
                self.notificationPermissionStatus = .denied
                self.notificationsEnabled = false
                self.dailyReminderEnabled = false
            }
            return false
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            await MainActor.run {
                self.microphonePermissionStatus = .granted
            }
            return true
        case .denied, .restricted:
            await MainActor.run {
                self.microphonePermissionStatus = .denied
                self.microphoneEnabled = false
            }
            return false
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            await MainActor.run {
                self.microphonePermissionStatus = granted ? .granted : .denied
                self.microphoneEnabled = granted
            }
            return granted
        @unknown default:
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func updateNotificationPermission() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        let permissionStatus: PermissionStatus = {
            switch status.authorizationStatus {
            case .authorized, .provisional, .ephemeral: return .granted
            case .denied: return .denied
            case .notDetermined: return .notRequested
            @unknown default: return .notRequested
            }
        }()
        
        await MainActor.run {
            self.notificationPermissionStatus = permissionStatus
            if permissionStatus != .granted {
                self.notificationsEnabled = false
                self.dailyReminderEnabled = false
            }
        }
    }
    
    private func updateMicrophonePermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        let permissionStatus: PermissionStatus = {
            switch status {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .denied
            case .notDetermined: return .notRequested
            @unknown default: return .notRequested
            }
        }()
        
        await MainActor.run {
            self.microphonePermissionStatus = permissionStatus
            if permissionStatus != .granted {
                self.microphoneEnabled = false
            }
        }
    }
    
    private func checkPermissions() async {
        await updateNotificationPermission()
        await updateMicrophonePermission()
        await syncNotificationSettings()
    }

    private func syncNotificationSettings() async {
        let identifiers = ["daily_reminder", "streak_reminder", "weekly_summary"]

        guard notificationsEnabled, notificationPermissionStatus == .granted else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            return
        }

        await scheduleDailyReminder()
        await scheduleStreakReminder()
        await scheduleWeeklySummary()
    }
    
    private func scheduleDailyReminder() async {
        if !notificationsEnabled || !dailyReminderEnabled {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
            return
        }
        
        guard notificationPermissionStatus == .granted else {
            logWarning("Cannot schedule reminder: notifications not permitted")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to learn!"
        content.body = "Keep your streak alive with today's lesson."
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: dailyReminderTime)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logAnalytics("daily_reminder_scheduled", ["time": dailyReminderTime.description])
        } catch {
            logError("Failed to schedule daily reminder", error)
        }
    }

    private func scheduleStreakReminder() async {
        let identifier = "streak_reminder"

        guard notificationsEnabled, streakReminderEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        guard notificationPermissionStatus == .granted else {
            logWarning("Cannot schedule streak reminder: notifications not permitted")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Protect your streak"
        content.body = "Spend a minute in Engify today to keep your streak going."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            logAnalytics("streak_reminder_scheduled", [:])
        } catch {
            logError("Failed to schedule streak reminder", error)
        }
    }

    private func scheduleWeeklySummary() async {
        let identifier = "weekly_summary"

        guard notificationsEnabled, weeklySummaryEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        guard notificationPermissionStatus == .granted else {
            logWarning("Cannot schedule weekly summary: notifications not permitted")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Your weekly progress is ready"
        content.body = "See your streak, points, and what to focus on next."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            logAnalytics("weekly_summary_scheduled", [:])
        } catch {
            logError("Failed to schedule weekly summary", error)
        }
    }
    
    private func deleteVoiceHistory() {
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let voiceFolder = (documentsPath as NSString).appendingPathComponent("voice_history")
        
        do {
            if fileManager.fileExists(atPath: voiceFolder) {
                try fileManager.removeItem(atPath: voiceFolder)
                logAnalytics("voice_history_deleted", [:])
            }
        } catch {
            logError("Failed to delete voice history", error)
        }
    }
    
    private func calculateVoiceHistoryStorage() async {
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let voiceFolder = (documentsPath as NSString).appendingPathComponent("voice_history")
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: voiceFolder)
            let size = files.reduce(0) { sum, file in
                let filePath = (voiceFolder as NSString).appendingPathComponent(file)
                let attr = try? fileManager.attributesOfItem(atPath: filePath)
                return sum + (attr?[.size] as? Int ?? 0)
            }
            await MainActor.run {
                self.voiceHistoryStorageUsage = size
            }
        } catch {
            // Folder doesn't exist yet
        }
    }
    
    private func analyzeGoalChange() {
        logAnalytics("learning_goal_changed", ["goal": learningGoal])
    }
    
    // MARK: - Persistence Helpers
    
    private func saveIfValid<T>(_ key: String, _ value: T, _ validate: (T) -> Bool) {
        guard validate(value) else {
            logWarning("Setting \(key) failed validation, reverting")
            return
        }
        save(key, value)
    }
    
    private func save(_ key: String, _ value: Any) {
        let fullKey = Keys.prefix + key
        if let data = value as? Data {
            UserDefaults.standard.set(data, forKey: fullKey)
        } else {
            UserDefaults.standard.set(value, forKey: fullKey)
        }
        logDebug("Setting persisted: \(key)")
    }

    private static func loadValidated<T>(_ key: String, default: T, validate: (T) -> Bool) -> T {
        if let value = loadValue(key, as: T.self), validate(value) {
            return value
        }
        return `default`
    }

    private static func loadValue<T>(_ key: String, as: T.Type) -> T? {
        let fullKey = Keys.prefix + key
        return UserDefaults.standard.object(forKey: fullKey) as? T
    }

    private static func loadBool(_ key: String, default: Bool) -> Bool {
        let fullKey = Keys.prefix + key
        if UserDefaults.standard.object(forKey: fullKey) == nil {
            return `default`
        }
        return UserDefaults.standard.bool(forKey: fullKey)
    }

    private static func loadDate(_ key: String, default: Date) -> Date {
        let fullKey = Keys.prefix + key
        if let timeInterval = UserDefaults.standard.object(forKey: fullKey) as? TimeInterval {
            return Date(timeIntervalSince1970: timeInterval)
        }
        return `default`
    }

    private static func loadString(_ key: String, default: String) -> String {
        let fullKey = Keys.prefix + key
        return UserDefaults.standard.string(forKey: fullKey) ?? `default`
    }

    private static func defaultReminderTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9  // 9 AM default
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }

    private func logAnalytics(_ event: String, _ params: [String: Any]) {
        // TODO: Integrate with Firebase Analytics or Amplitude
        print("[Analytics] \(event): \(params)")
    }

    private func logError(_ message: String, _ error: Error) {
        print("[ERROR] \(message): \(error.localizedDescription)")
        // TODO: Log to Sentry or similar crash reporting
    }

    private func logWarning(_ message: String) {
        print("[WARNING] \(message)")
    }

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[DEBUG] \(message)")
        #endif
    }
    
    // MARK: - Preset Management
    
    /// Applies a settings preset, updating all learning-related settings to curated values.
    /// Permission-gated settings (notifications, microphone) are not modified by presets.
    func applyPreset(_ preset: SettingsPreset) {
        let values = preset.values
        
        learningGoal = values.learningGoal
        explanationDepth = values.explanationDepth
        correctionStyle = values.correctionStyle
        generateExtraExamples = values.generateExtraExamples
        
        speechFeedbackEnabled = values.speechFeedbackEnabled
        transcriptVisible = values.transcriptVisible
        speakingSpeed = values.speakingSpeed
        pronunciationModel = values.pronunciationModel
        repeatPronunciation = values.repeatPronunciation
        
        newWordsPerDay = values.newWordsPerDay
        reviewLimitPerDay = values.reviewLimitPerDay
        difficultyLock = values.difficultyLock
        
        showDefinitionsByDefault = values.showDefinitionsByDefault
        showGrammarCorrections = values.showGrammarCorrections
        
        soundEffectsEnabled = values.soundEffectsEnabled
        soundEffectStyle = values.soundEffectStyle
        hapticFeedbackEnabled = values.hapticFeedbackEnabled
        
        activePreset = preset
        logAnalytics("settings_preset_applied", ["preset": preset.rawValue])
    }
    
    /// Resets all settings to the Engify Default preset.
    func resetToDefaults() {
        applyPreset(.default)
        dictionaryAPIBaseURL = ""
    }
}

// MARK: - Settings Preset

/// Pre-configured settings profiles that users can quickly apply.
///
/// Each preset defines a curated combination of learning settings optimized for
/// a specific use case. Permission-gated settings (notifications, microphone)
/// are intentionally excluded from presets.
enum SettingsPreset: String, CaseIterable, Identifiable {
    case `default` = "default"
    case casual = "casual"
    case intensive = "intensive"
    case examPrep = "exam_prep"
    case minimal = "minimal"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .default: return "Engify Default"
        case .casual: return "Casual Learner"
        case .intensive: return "Intensive Study"
        case .examPrep: return "Exam Prep"
        case .minimal: return "Minimal"
        }
    }
    
    var subtitle: String {
        switch self {
        case .default: return "Balanced settings for everyday learning."
        case .casual: return "Relaxed pace with gentle corrections."
        case .intensive: return "Maximum practice with detailed feedback."
        case .examPrep: return "Strict corrections, high volume, exam focus."
        case .minimal: return "Stripped-down experience, fewer distractions."
        }
    }
    
    var icon: String {
        switch self {
        case .default: return "star.fill"
        case .casual: return "leaf.fill"
        case .intensive: return "flame.fill"
        case .examPrep: return "graduationcap.fill"
        case .minimal: return "circle.dotted"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .default: return EngifyColors.accent
        case .casual: return EngifyColors.sky
        case .intensive: return EngifyColors.coral
        case .examPrep: return EngifyColors.warning
        case .minimal: return EngifyColors.textSecondary
        }
    }
    
    /// The curated setting values for this preset.
    var values: SettingsPresetValues {
        switch self {
        case .default:
            return SettingsPresetValues(
                learningGoal: "daily",
                explanationDepth: "balanced",
                correctionStyle: "gentle",
                generateExtraExamples: true,
                speechFeedbackEnabled: true,
                transcriptVisible: true,
                speakingSpeed: "normal",
                pronunciationModel: "us_english",
                repeatPronunciation: false,
                newWordsPerDay: 8,
                reviewLimitPerDay: 15,
                difficultyLock: false,
                showDefinitionsByDefault: false,
                showGrammarCorrections: true,
                soundEffectsEnabled: true,
                soundEffectStyle: SoundEffectStyle.classic.rawValue,
                hapticFeedbackEnabled: true
            )
        case .casual:
            return SettingsPresetValues(
                learningGoal: "daily",
                explanationDepth: "simple",
                correctionStyle: "gentle",
                generateExtraExamples: false,
                speechFeedbackEnabled: true,
                transcriptVisible: true,
                speakingSpeed: "slow",
                pronunciationModel: "us_english",
                repeatPronunciation: false,
                newWordsPerDay: 3,
                reviewLimitPerDay: 8,
                difficultyLock: false,
                showDefinitionsByDefault: true,
                showGrammarCorrections: false,
                soundEffectsEnabled: true,
                soundEffectStyle: SoundEffectStyle.soft.rawValue,
                hapticFeedbackEnabled: true
            )
        case .intensive:
            return SettingsPresetValues(
                learningGoal: "study",
                explanationDepth: "detailed",
                correctionStyle: "balanced",
                generateExtraExamples: true,
                speechFeedbackEnabled: true,
                transcriptVisible: true,
                speakingSpeed: "normal",
                pronunciationModel: "us_english",
                repeatPronunciation: true,
                newWordsPerDay: 15,
                reviewLimitPerDay: 30,
                difficultyLock: true,
                showDefinitionsByDefault: true,
                showGrammarCorrections: true,
                soundEffectsEnabled: true,
                soundEffectStyle: SoundEffectStyle.bright.rawValue,
                hapticFeedbackEnabled: true
            )
        case .examPrep:
            return SettingsPresetValues(
                learningGoal: "exam",
                explanationDepth: "detailed",
                correctionStyle: "strict",
                generateExtraExamples: true,
                speechFeedbackEnabled: true,
                transcriptVisible: false,
                speakingSpeed: "fast",
                pronunciationModel: "uk_english",
                repeatPronunciation: true,
                newWordsPerDay: 20,
                reviewLimitPerDay: 40,
                difficultyLock: true,
                showDefinitionsByDefault: false,
                showGrammarCorrections: true,
                soundEffectsEnabled: false,
                soundEffectStyle: SoundEffectStyle.classic.rawValue,
                hapticFeedbackEnabled: true
            )
        case .minimal:
            return SettingsPresetValues(
                learningGoal: "daily",
                explanationDepth: "simple",
                correctionStyle: "gentle",
                generateExtraExamples: false,
                speechFeedbackEnabled: false,
                transcriptVisible: false,
                speakingSpeed: "normal",
                pronunciationModel: "us_english",
                repeatPronunciation: false,
                newWordsPerDay: 5,
                reviewLimitPerDay: 10,
                difficultyLock: false,
                showDefinitionsByDefault: false,
                showGrammarCorrections: false,
                soundEffectsEnabled: false,
                soundEffectStyle: SoundEffectStyle.soft.rawValue,
                hapticFeedbackEnabled: false
            )
        }
    }
}

/// The concrete values for a settings preset.
struct SettingsPresetValues {
    let learningGoal: String
    let explanationDepth: String
    let correctionStyle: String
    let generateExtraExamples: Bool
    let speechFeedbackEnabled: Bool
    let transcriptVisible: Bool
    let speakingSpeed: String
    let pronunciationModel: String
    let repeatPronunciation: Bool
    let newWordsPerDay: Int
    let reviewLimitPerDay: Int
    let difficultyLock: Bool
    let showDefinitionsByDefault: Bool
    let showGrammarCorrections: Bool
    let soundEffectsEnabled: Bool
    let soundEffectStyle: String
    let hapticFeedbackEnabled: Bool
}

enum SoundEffectStyle: String, CaseIterable, Identifiable {
    case classic = "classic"
    case soft = "soft"
    case bright = "bright"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic:
            return "Classic"
        case .soft:
            return "Soft"
        case .bright:
            return "Bright"
        }
    }

    var subtitle: String {
        switch self {
        case .classic:
            return "Balanced pops and taps."
        case .soft:
            return "Gentler and more muted."
        case .bright:
            return "Sharper and more playful."
        }
    }
}

// MARK: - Permission Status

enum PermissionStatus: String, CaseIterable {
    case notRequested = "Not Requested"
    case granted = "Granted"
    case denied = "Denied"
    case restricted = "Restricted"
    
    var icon: String {
        switch self {
        case .granted: return "checkmark.circle.fill"
        case .denied, .restricted: return "xmark.circle.fill"
        case .notRequested: return "circle"
        }
    }
    
    var color: Color {
        switch self {
        case .granted: return EngifyColors.sage
        case .denied, .restricted: return EngifyColors.coral
        case .notRequested: return EngifyColors.textSecondary
        }
    }
}
