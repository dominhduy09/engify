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

    // Request publisher for lesson completion overlay
    let lessonCompletionRequest = PassthroughSubject<LessonResult, Never>()

    private var cancellables = Set<AnyCancellable>()
    private let supabaseManager: SupabaseManager
    private var currentUserID: String?
    private var isApplyingRemoteState = false
    private var awardedPointRewardKeys: Set<String>

    // MARK: - Init

    init(supabaseManager: SupabaseManager = .shared) {
        self.supabaseManager = supabaseManager
        self.awardedPointRewardKeys = Self.loadAwardedPointRewardKeys()
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
        save()
    }

    /// Called when a lesson is completed. Awards XP, lingots, and triggers the overlay.
    func completeLesson(type: LessonType, xpEarned: Int, lingotsEarned: Int = 0) {
        let result = LessonResult(lessonType: type, xpEarned: xpEarned, lingotsEarned: lingotsEarned)
        currentLessonResult = result
        saveCompletedLesson(result)
        earnXP(xpEarned)
        if lingotsEarned > 0 {
            addLingots(lingotsEarned)
        }
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
    }

    private static let milestoneLevels: Set<Int> = {
        var levels: Set<Int> = [2, 5]
        stride(from: 10, through: 100, by: 10).forEach { levels.insert($0) }
        return levels
    }()
}
