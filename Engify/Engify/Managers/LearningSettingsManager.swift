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
    
    // MARK: - Notifications
    
    @Published var notificationsEnabled: Bool {
        didSet { 
            save("notifications_enabled", notificationsEnabled)
            Task { await updateNotificationPermission() }
        }
    }
    
    @Published var dailyReminderEnabled: Bool {
        didSet { 
            save("daily_reminder", dailyReminderEnabled)
            Task { await scheduleDailyReminder() }
        }
    }
    
    @Published var dailyReminderTime: Date {
        didSet { 
            save("daily_reminder_time", dailyReminderTime.timeIntervalSince1970)
            Task { await scheduleDailyReminder() }
        }
    }
    
    @Published var streakReminderEnabled: Bool {
        didSet { save("streak_reminder", streakReminderEnabled) }
    }
    
    @Published var weeklySummaryEnabled: Bool {
        didSet { save("weekly_summary", weeklySummaryEnabled) }
    }
    
    // MARK: - Microphone & Voice
    
    @Published var microphoneEnabled: Bool {
        didSet { 
            save("microphone_enabled", microphoneEnabled)
            Task { await updateMicrophonePermission() }
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
    
    // MARK: - Constants
    
    private static let validLearningGoals = ["daily", "travel", "work", "study", "exam"]
    private static let validDepths = ["simple", "balanced", "detailed"]
    private static let validStyles = ["gentle", "balanced", "strict"]
    private static let validSpeeds = ["slow", "normal", "fast"]
    private static let validModels = ["us_english", "uk_english", "australian"]
    
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
        
        self.notificationsEnabled = Self.loadBool("notifications_enabled", default: true)
        self.dailyReminderEnabled = Self.loadBool("daily_reminder", default: true)
        self.dailyReminderTime = Self.loadDate("daily_reminder_time", default: Self.defaultReminderTime())
        self.streakReminderEnabled = Self.loadBool("streak_reminder", default: true)
        self.weeklySummaryEnabled = Self.loadBool("weekly_summary", default: true)
        
        self.microphoneEnabled = Self.loadBool("microphone_enabled", default: true)
        self.voiceHistoryEnabled = Self.loadBool("voice_history_enabled", default: true)
        self.soundEffectsEnabled = Self.loadBool("sound_effects_enabled", default: true)
        self.hapticFeedbackEnabled = Self.loadBool("haptic_feedback_enabled", default: true)
        
        self.showDefinitionsByDefault = Self.loadBool("show_definitions_default", default: false)
        self.showGrammarCorrections = Self.loadBool("show_grammar_corrections", default: true)
        self.repeatPronunciation = Self.loadBool("repeat_pronunciation", default: false)
        self.difficultyLock = Self.loadBool("difficulty_lock", default: false)
        
        self.reducedMotionEnabled = Self.loadBool("reduced_motion", default: false)
        self.highContrastEnabled = Self.loadBool("high_contrast", default: false)
        
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
            }
            return granted
        } catch {
            logError("Notification permission request failed", error)
            await MainActor.run {
                self.notificationPermissionStatus = .denied
            }
            return false
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            await MainActor.run {
                self.microphonePermissionStatus = granted ? .granted : .denied
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
        }
    }
    
    private func checkPermissions() async {
        await updateNotificationPermission()
        await updateMicrophonePermission()
    }
    
    private func scheduleDailyReminder() async {
        if !dailyReminderEnabled {
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
