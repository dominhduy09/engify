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
    }

    // MARK: - Published State

    @Published var progress: UserProgress
    @Published var showLessonComplete = false
    @Published var currentLessonResult: LessonResult?
    @Published var showXPGain = false
    @Published var lastXPGained: Int = 0

    // Request publisher for lesson completion overlay
    let lessonCompletionRequest = PassthroughSubject<LessonResult, Never>()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        if let data = UserDefaults.standard.data(forKey: Keys.progress),
           let decoded = try? JSONDecoder().decode(UserProgress.self, from: data) {
            self.progress = decoded
        } else {
            self.progress = .initial
        }

        checkStreak()
        subscribeToLessonCompletion()
    }

    // MARK: - Public Methods

    /// Adds XP and triggers the XP gain toast animation.
    func earnXP(_ amount: Int) {
        let wasBelowThreshold = progress.xp < progress.xpForNextLevel
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

        if wasBelowThreshold && progress.xp >= progress.xpForNextLevel {
            triggerLevelUp()
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

    // MARK: - Private Methods

    private func save() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: Keys.progress)
        }
    }

    private func saveCompletedLesson(_ lesson: LessonResult) {
        var lessons = completedLessons
        lessons.append(lesson)
        if let encoded = try? JSONEncoder().encode(lessons) {
            UserDefaults.standard.set(encoded, forKey: Keys.completedLessons)
        }
    }

    private var completedLessons: [LessonResult] {
        guard let data = UserDefaults.standard.data(forKey: Keys.completedLessons),
              let decoded = try? JSONDecoder().decode([LessonResult].self, from: data) else {
            return []
        }
        return decoded
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

    /// Checks if the user was active yesterday. If so, increments streak;
    /// if they were active today already, does nothing; otherwise resets streak.
    private func checkStreak() {
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
        save()
    }

    private func triggerLevelUp() {
        // Level-up is implied by progress.level increasing;
        // views can react to this via the @Published progress.level change.
        // The overlay handles the visual celebration.
    }
}
