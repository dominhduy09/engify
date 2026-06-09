import Combine
import Foundation
import SwiftUI

/// Manages all gamification state: XP, level, streak, hearts, lingots, and lesson results.
/// Persists progress to UserDefaults and broadcasts changes via @Published.
///
/// WHAT IT DOES:
/// - Holds UserProgress (xp, level, streak, hearts, lingots) as @Published state.
/// - Provides earnXP(), loseHeart(), restoreHearts(), addLingots(), incrementStreak().
/// - Tracks completed lessons as [LessonResult] for history.
/// - Checks and updates daily streak on app launch based on lastActiveDate.
///
/// WHEN IT SHOWS:
/// - Injected as @EnvironmentObject from EngifyApp to every view in the app.
/// - HomeView reads streak/hearts/XP for the dashboard.
/// - VocabularyView and PracticeView call earnXP/loseHeart on lesson events.
/// - LessonCompleteOverlay is triggered by lessonCompletionRequest.
///
/// HOW IT WORKS:
/// - progress is persisted to UserDefaults as JSON after every mutation.
/// - lessonCompletionRequest is a PassthroughSubject used by child views to request
///   the LessonCompleteOverlay — views subscribe and show the overlay on receipt.
/// - checkStreak() is called on init and determines whether to increment the streak
///   or reset it based on whether the user was active yesterday.
@MainActor
final class GamificationManager: ObservableObject {
    private enum Keys {
        static let progress = "engify.gamification.progress"
        static let completedLessons = "engify.gamification.completed-lessons"
        static let awardedPointRewards = "engify.gamification.awarded-point-rewards"
        static let unlockedBadges = "engify.gamification.unlocked-badges"
        static let badgeStats = "engify.gamification.badge-stats"
    }

    // MARK: - Published State

    @Published var progress: UserProgress
    @Published var showLessonComplete = false
    @Published var currentLessonResult: LessonResult?
    @Published var showXPGain = false
    @Published var showLevelUp = false
    @Published var lastXPGained: Int = 0
    @Published var lastUnlockedLevel: Int?
    @Published var lastLevelUpWasMilestone = false
    @Published private(set) var unlockedBadges: Set<AchievementBadge>
    @Published private(set) var latestUnlockedBadge: AchievementBadge?
    @Published var showBadgeUnlocked = false

    // Request publisher for lesson completion overlay
    let lessonCompletionRequest = PassthroughSubject<LessonResult, Never>()

    private var cancellables = Set<AnyCancellable>()
    private let supabaseManager: SupabaseManager
    private var currentUserID: String?
    private var isApplyingRemoteState = false
    private var awardedPointRewardKeys: Set<String>
    private var badgeStats: BadgeProgressStats
    private var badgeUnlockQueue: [AchievementBadge] = []
    private var badgeDismissWorkItem: DispatchWorkItem?

    // MARK: - Init

    init(supabaseManager: SupabaseManager = .shared) {
        self.supabaseManager = supabaseManager
        self.awardedPointRewardKeys = Self.loadAwardedPointRewardKeys()
        self.unlockedBadges = Self.loadUnlockedBadges()
        self.badgeStats = Self.loadBadgeStats()
        if let data = UserDefaults.standard.data(forKey: Keys.progress),
           let decoded = try? JSONDecoder().decode(UserProgress.self, from: data) {
            var normalized = decoded
            normalized.normalizeLevel()
            self.progress = normalized
        } else {
            self.progress = .initial
        }

        reconcileDailyStreak()
        subscribeToLessonCompletion()
    }

    // MARK: - Public Methods

    /// Adds XP and triggers the XP gain toast animation.
    func earnXP(_ amount: Int) {
        let previousLevel = progress.level
        progress.earnXP(amount)
        lastXPGained = amount
        save()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showXPGain = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.showXPGain = false
            }
        }

        if progress.level > previousLevel {
            triggerLevelUp(level: progress.level)
        }
    }

    /// Removes one heart and saves state.
    func loseHeart() {
        guard progress.hearts > 0 else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            progress.loseHeart()
        }
        save()
    }

    /// Restores all hearts to max and saves.
    func restoreHearts() {
        withAnimation(.easeInOut(duration: 0.5)) {
            progress.restoreHearts()
        }
        save()
    }

    /// Awards lingots with a bounce animation.
    func addLingots(_ count: Int) {
        progress.addLingots(count)
        save()
    }

    @discardableResult
    func awardPoints(for event: PointsRewardEvent) -> PointsRewardResult {
        let rewardKey = event.rewardKey

        guard !awardedPointRewardKeys.contains(rewardKey) else {
            return .alreadyAwarded(totalPoints: progress.points)
        }

        progress.addPoints(event.pointsAwarded)
        awardedPointRewardKeys.insert(rewardKey)
        persistAwardedPointRewardKeys()
        registerPointsActivity()
        evaluateBadgeUnlocks(triggeredAt: Date())
        save()

        return .awarded(amount: event.pointsAwarded, totalPoints: progress.points)
    }

    @discardableResult
    func spendPoints(_ count: Int) -> Bool {
        guard progress.points >= count, count > 0 else { return false }
        progress.spendPoints(count)
        save()
        return true
    }

    /// Increments the daily streak counter.
    func incrementStreak() {
        progress.incrementStreak()
        evaluateBadgeUnlocks(triggeredAt: Date())
        save()
    }

    /// Called when a lesson is completed. Awards XP, lingots, and triggers the overlay.
    func completeLesson(type: LessonType, xpEarned: Int, lingotsEarned: Int = 0) {
        let result = LessonResult(lessonType: type, xpEarned: xpEarned, lingotsEarned: lingotsEarned)
        currentLessonResult = result
        saveCompletedLesson(result)
        registerLessonCompletion(result)
        earnXP(xpEarned)
        if lingotsEarned > 0 {
            addLingots(lingotsEarned)
        }
        evaluateBadgeUnlocks(triggeredAt: result.completedAt)
        showLessonComplete = true
    }

    /// Hides the lesson complete overlay.
    func dismissLessonComplete() {
        showLessonComplete = false
        currentLessonResult = nil
    }

    func loadFromRemote(for userID: String) async {
        currentUserID = userID

        do {
            if let remoteProgress = try await supabaseManager.fetchUserProgress(userId: userID) {
                isApplyingRemoteState = true
                var normalized = remoteProgress
                normalized.normalizeLevel()
                progress = normalized
                isApplyingRemoteState = false
                reconcileDailyStreak()
            } else {
                reconcileDailyStreak()
                await supabaseManager.syncUserData(progress: progress)
            }
        } catch {
            print("Failed to load remote progress: \(error.localizedDescription)")
        }
    }

    func clearRemoteSession() {
        currentUserID = nil
    }

    var recentLessonResults: [LessonResult] {
        completedLessons.sorted { $0.completedAt > $1.completedAt }
    }

    func registerSavedWord(source: SavedWordEvent, at date: Date = Date()) {
        let normalizedWordID = normalizedSavedWordID(for: source)
        guard badgeStats.savedWordIDs.insert(normalizedWordID).inserted else { return }
        badgeStats.totalSavedWords = badgeStats.savedWordIDs.count
        evaluateBadgeUnlocks(triggeredAt: date)
        persistBadgeStats()
        save()
    }

    func registerLookup(wordID: String, at date: Date = Date()) {
        let normalized = wordID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return }
        badgeStats.lookedUpWordIDs.insert(normalized)
        evaluateBadgeUnlocks(triggeredAt: date)
        persistBadgeStats()
    }

    func registerPerfectNewsQuiz(at date: Date = Date()) {
        badgeStats.perfectNewsQuizCount += 1
        evaluateBadgeUnlocks(triggeredAt: date)
        persistBadgeStats()
        save()
    }

    func dismissBadgeUnlocked() {
        badgeDismissWorkItem?.cancel()
        badgeDismissWorkItem = nil

        if let latestUnlockedBadge,
           let queueIndex = badgeUnlockQueue.firstIndex(of: latestUnlockedBadge) {
            badgeUnlockQueue.remove(at: queueIndex)
        }

        showBadgeUnlocked = false
        latestUnlockedBadge = nil

        guard !badgeUnlockQueue.isEmpty else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            self?.presentNextBadgeIfNeeded()
        }
    }

    func isBadgeUnlocked(_ badge: AchievementBadge) -> Bool {
        unlockedBadges.contains(badge)
    }

    // MARK: - Private Methods

    private func save() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: Keys.progress)
        }

        guard currentUserID != nil, !isApplyingRemoteState else { return }

        let snapshot = progress
        Task {
            await supabaseManager.syncUserData(progress: snapshot)
        }
    }

    private func saveCompletedLesson(_ lesson: LessonResult) {
        var lessons = completedLessons
        lessons.append(lesson)
        if let encoded = try? JSONEncoder().encode(lessons) {
            UserDefaults.standard.set(encoded, forKey: Keys.completedLessons)
        }

        guard currentUserID != nil else { return }

        Task {
            do {
                try await supabaseManager.saveLessonResult(lesson)
            } catch {
                print("Failed to save lesson result: \(error.localizedDescription)")
            }
        }
    }

    private var completedLessons: [LessonResult] {
        guard let data = UserDefaults.standard.data(forKey: Keys.completedLessons),
              let decoded = try? JSONDecoder().decode([LessonResult].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func loadAwardedPointRewardKeys() -> Set<String> {
        guard let values = UserDefaults.standard.array(forKey: Keys.awardedPointRewards) as? [String] else {
            return []
        }
        return Set(values)
    }

    private func persistAwardedPointRewardKeys() {
        UserDefaults.standard.set(Array(awardedPointRewardKeys).sorted(), forKey: Keys.awardedPointRewards)
    }

    private static func loadUnlockedBadges() -> Set<AchievementBadge> {
        guard let values = UserDefaults.standard.array(forKey: Keys.unlockedBadges) as? [String] else {
            return []
        }
        return Set(values.compactMap(AchievementBadge.init(rawValue:)))
    }

    private func persistUnlockedBadges() {
        UserDefaults.standard.set(unlockedBadges.map(\.rawValue).sorted(), forKey: Keys.unlockedBadges)
    }

    private static func loadBadgeStats() -> BadgeProgressStats {
        guard let data = UserDefaults.standard.data(forKey: Keys.badgeStats),
              let decoded = try? JSONDecoder().decode(BadgeProgressStats.self, from: data) else {
            return .initial
        }
        return decoded
    }

    private func persistBadgeStats() {
        if let encoded = try? JSONEncoder().encode(badgeStats) {
            UserDefaults.standard.set(encoded, forKey: Keys.badgeStats)
        }
    }

    private func subscribeToLessonCompletion() {
        lessonCompletionRequest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.currentLessonResult = result
                self?.showLessonComplete = true
            }
            .store(in: &cancellables)
    }

    /// Reconciles the streak for the current calendar day, then persists the result.
    private func reconcileDailyStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActive = progress.lastActiveDate {
            let lastActiveDay = calendar.startOfDay(for: lastActive)
            let daysDiff = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

            if daysDiff == 1 {
                // User was active yesterday — increment streak
                incrementStreak()
            } else if daysDiff > 1 {
                // Streak broken — reset
                progress.streakDays = 1
                save()
            }
        } else if progress.streakDays == 0 {
            // First time user — start at day 1
            progress.streakDays = 1
            save()
        }

        // Update last active date
        progress.lastActiveDate = Date()
        progress.normalizeLevel()
        save()
    }

    private func triggerLevelUp(level: Int) {
        lastUnlockedLevel = level
        lastLevelUpWasMilestone = Self.milestoneLevels.contains(level)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            showLevelUp = true
        }
        evaluateBadgeUnlocks(triggeredAt: Date())
    }

    private func registerLessonCompletion(_ result: LessonResult) {
        let hour = Calendar.current.component(.hour, from: result.completedAt)
        if hour < 8 {
            badgeStats.hasCompletedEarlyBirdLesson = true
        }
        if hour >= 22 {
            badgeStats.hasCompletedNightOwlLesson = true
        }

        if result.lessonType == .practice, result.xpEarned >= 20 {
            badgeStats.perfectPracticeCount += 1
        }

        persistBadgeStats()
    }

    private func registerPointsActivity(on date: Date = Date()) {
        registerPointsActivity(dayKey: Self.dayKey(for: date))
    }

    private func registerPointsActivity() {
        registerPointsActivity(on: Date())
    }

    private func registerPointsActivity(dayKey: String) {
        badgeStats.dailyPointActivity[dayKey, default: 0] += 1
        trimOldPointActivity()
        persistBadgeStats()
    }

    private func trimOldPointActivity() {
        let validKeys = Set(
            (0..<14).compactMap { offset in
                Calendar.current.date(byAdding: .day, value: -offset, to: Date()).map(Self.dayKey(for:))
            }
        )
        badgeStats.dailyPointActivity = badgeStats.dailyPointActivity.filter { validKeys.contains($0.key) }
    }

    private func evaluateBadgeUnlocks(triggeredAt date: Date) {
        unlockIfNeeded(.earlyBird, when: badgeStats.hasCompletedEarlyBirdLesson)
        unlockIfNeeded(.nightOwl, when: badgeStats.hasCompletedNightOwlLesson)
        unlockIfNeeded(.wordCollector, when: badgeStats.totalSavedWords >= 10)
        unlockIfNeeded(.wordSmith, when: badgeStats.totalSavedWords >= 50)
        unlockIfNeeded(.consistentLearner, when: progress.streakDays >= 7)
        unlockIfNeeded(.streakKeeper, when: progress.streakDays >= 30)
        unlockIfNeeded(.quizAce, when: badgeStats.perfectPracticeCount >= 1)
        unlockIfNeeded(.sharpReader, when: badgeStats.perfectNewsQuizCount >= 5)
        unlockIfNeeded(.explorer, when: badgeStats.lookedUpWordIDs.count >= 25)
        unlockIfNeeded(.momentum, when: badgeStats.dailyPointActivity[Self.dayKey(for: date), default: 0] >= 3)
        unlockIfNeeded(.levelClimber, when: progress.resolvedLevel >= 10)
        unlockIfNeeded(.centuryStar, when: progress.points >= 100)
    }

    private func unlockIfNeeded(_ badge: AchievementBadge, when condition: Bool) {
        guard condition, !unlockedBadges.contains(badge) else { return }
        unlockedBadges.insert(badge)
        persistUnlockedBadges()
        badgeUnlockQueue.append(badge)
        presentNextBadgeIfNeeded()
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static let milestoneLevels: Set<Int> = {
        var levels: Set<Int> = [2, 5]
        stride(from: 10, through: 100, by: 10).forEach { levels.insert($0) }
        return levels
    }()

    private func presentNextBadgeIfNeeded() {
        guard latestUnlockedBadge == nil, let nextBadge = badgeUnlockQueue.first else { return }

        latestUnlockedBadge = nextBadge
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            showBadgeUnlocked = true
        }
        scheduleBadgeDismiss()
    }

    private func scheduleBadgeDismiss() {
        badgeDismissWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                self.dismissBadgeUnlocked()
            }
        }

        badgeDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: workItem)
    }

    private func normalizedSavedWordID(for source: SavedWordEvent) -> String {
        switch source {
        case let .dictionary(entry):
            return entry.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        case let .vocabulary(word):
            return word.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
}

private struct BadgeProgressStats: Codable {
    var totalSavedWords: Int
    var savedWordIDs: Set<String>
    var perfectPracticeCount: Int
    var perfectNewsQuizCount: Int
    var hasCompletedEarlyBirdLesson: Bool
    var hasCompletedNightOwlLesson: Bool
    var lookedUpWordIDs: Set<String>
    var dailyPointActivity: [String: Int]

    private enum CodingKeys: String, CodingKey {
        case totalSavedWords
        case savedWordIDs
        case perfectPracticeCount
        case perfectNewsQuizCount
        case hasCompletedEarlyBirdLesson
        case hasCompletedNightOwlLesson
        case lookedUpWordIDs
        case dailyPointActivity
        case lookupSaveCount
    }

    init(
        totalSavedWords: Int,
        savedWordIDs: Set<String>,
        perfectPracticeCount: Int,
        perfectNewsQuizCount: Int,
        hasCompletedEarlyBirdLesson: Bool,
        hasCompletedNightOwlLesson: Bool,
        lookedUpWordIDs: Set<String>,
        dailyPointActivity: [String: Int]
    ) {
        self.totalSavedWords = totalSavedWords
        self.savedWordIDs = savedWordIDs
        self.perfectPracticeCount = perfectPracticeCount
        self.perfectNewsQuizCount = perfectNewsQuizCount
        self.hasCompletedEarlyBirdLesson = hasCompletedEarlyBirdLesson
        self.hasCompletedNightOwlLesson = hasCompletedNightOwlLesson
        self.lookedUpWordIDs = lookedUpWordIDs
        self.dailyPointActivity = dailyPointActivity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let savedWordIDs = try container.decodeIfPresent(Set<String>.self, forKey: .savedWordIDs) ?? []
        let legacySavedWordCount = try container.decodeIfPresent(Int.self, forKey: .totalSavedWords) ?? 0

        self.savedWordIDs = savedWordIDs
        self.totalSavedWords = max(legacySavedWordCount, savedWordIDs.count)
        self.perfectPracticeCount = try container.decodeIfPresent(Int.self, forKey: .perfectPracticeCount) ?? 0
        self.perfectNewsQuizCount = try container.decodeIfPresent(Int.self, forKey: .perfectNewsQuizCount) ?? 0
        self.hasCompletedEarlyBirdLesson = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedEarlyBirdLesson) ?? false
        self.hasCompletedNightOwlLesson = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedNightOwlLesson) ?? false
        self.lookedUpWordIDs = try container.decodeIfPresent(Set<String>.self, forKey: .lookedUpWordIDs) ?? []
        self.dailyPointActivity = try container.decodeIfPresent([String: Int].self, forKey: .dailyPointActivity) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalSavedWords, forKey: .totalSavedWords)
        try container.encode(savedWordIDs, forKey: .savedWordIDs)
        try container.encode(perfectPracticeCount, forKey: .perfectPracticeCount)
        try container.encode(perfectNewsQuizCount, forKey: .perfectNewsQuizCount)
        try container.encode(hasCompletedEarlyBirdLesson, forKey: .hasCompletedEarlyBirdLesson)
        try container.encode(hasCompletedNightOwlLesson, forKey: .hasCompletedNightOwlLesson)
        try container.encode(lookedUpWordIDs, forKey: .lookedUpWordIDs)
        try container.encode(dailyPointActivity, forKey: .dailyPointActivity)
    }

    static var initial: BadgeProgressStats {
        BadgeProgressStats(
            totalSavedWords: 0,
            savedWordIDs: [],
            perfectPracticeCount: 0,
            perfectNewsQuizCount: 0,
            hasCompletedEarlyBirdLesson: false,
            hasCompletedNightOwlLesson: false,
            lookedUpWordIDs: [],
            dailyPointActivity: [:]
        )
    }
}
