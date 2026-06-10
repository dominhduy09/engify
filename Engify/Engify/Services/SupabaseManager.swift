import Combine
import Foundation
import Supabase

@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    let client: SupabaseClient?

    @Published private(set) var isInitialized = false
    @Published private(set) var authError: String?

    private init(provider: SupabaseClientProvider? = nil) {
        let provider = provider ?? .shared
        self.client = provider.client
        self.isInitialized = provider.client != nil
        self.authError = provider.configurationError?.localizedDescription
    }

    var currentSession: Session? {
        client?.auth.currentSession
    }

    var currentUser: UserInfo? {
        client?.auth.currentUser
    }

    func upsertUserProfile(userID: String, email: String, displayName: String) async throws {
        let profile = UserProfile(
            id: userID,
            email: email,
            displayName: displayName
        )

        try await configuredClient()
            .from("users")
            .upsert(profile)
            .execute()
    }

    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let response: PostgrestResponse<UserProfile> = try await configuredClient()
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()

        return response.value
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        try await configuredClient()
            .from("users")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }

    func saveOnboardingSurvey(_ response: OnboardingSurveyResponse) async throws {
        guard let userID = currentUser?.id.uuidString else { return }

        let payload = OnboardingSurveyData(
            userId: userID,
            learningGoal: response.learningGoal,
            englishLevel: response.englishLevel,
            dailyStudyMinutes: response.dailyStudyMinutes,
            biggestChallenge: response.biggestChallenge,
            submittedAt: response.submittedAt
        )

        try await configuredClient()
            .from("onboarding_surveys")
            .upsert(payload)
            .execute()
    }

    func saveUserProgress(_ progress: UserProgress) async throws {
        guard let userID = currentUser?.id.uuidString else { return }

        var normalized = progress
        normalized.normalizeLevel()

        let data = UserProgressData(
            userId: userID,
            xp: normalized.xp,
            level: normalized.resolvedLevel,
            streakDays: normalized.streakDays,
            hearts: normalized.hearts,
            maxHearts: normalized.maxHearts,
            lingots: normalized.lingots,
            lastActiveDate: normalized.lastActiveDate
        )

        try await configuredClient()
            .from("user_progress")
            .upsert(data)
            .execute()
    }

    func fetchUserProgress(userId: String) async throws -> UserProgress? {
        do {
            let response: PostgrestResponse<UserProgressData> = try await configuredClient()
                .from("user_progress")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()

            var progress = UserProgress(
                xp: response.value.xp,
                level: response.value.level,
                streakDays: response.value.streakDays,
                hearts: response.value.hearts,
                maxHearts: response.value.maxHearts,
                lingots: response.value.lingots,
                lastActiveDate: response.value.lastActiveDate
            )
            progress.normalizeLevel()
            return progress
        } catch {
            return nil
        }
    }

    func saveWord(_ word: Word) async throws {
        guard let userID = currentUser?.id.uuidString else { return }

        let stableWordID = word.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let savedWord = SavedWordData(
            userId: userID,
            wordId: stableWordID,
            word: word.word,
            pronunciation: word.pronunciation,
            partOfSpeech: word.partOfSpeech,
            meaning: word.meaning,
            example: word.example,
            savedAt: Date()
        )

        try await configuredClient()
            .from("saved_words")
            .insert(savedWord)
            .execute()
    }

    func fetchSavedWords(userId: String) async throws -> [Word] {
        let response: PostgrestResponse<[SavedWordData]> = try await configuredClient()
            .from("saved_words")
            .select()
            .eq("user_id", value: userId)
            .order("saved_at", ascending: false)
            .execute()

        return response.value.map { data in
            Word(
                id: UUID(),
                word: data.word,
                pronunciation: data.pronunciation,
                partOfSpeech: data.partOfSpeech,
                meaning: data.meaning,
                example: data.example
            )
        }
    }

    func deleteSavedWord(userId: String, wordId: String) async throws {
        try await configuredClient()
            .from("saved_words")
            .delete()
            .eq("user_id", value: userId)
            .eq("word_id", value: wordId)
            .execute()
    }

    func saveLessonResult(_ result: LessonResult) async throws {
        guard let userID = currentUser?.id.uuidString else { return }

        let data = LessonResultData(
            id: result.id.uuidString,
            userId: userID,
            lessonType: result.lessonType.rawValue,
            xpEarned: result.xpEarned,
            lingotsEarned: result.lingotsEarned,
            completedAt: result.completedAt
        )

        try await configuredClient()
            .from("lesson_results")
            .insert(data)
            .execute()
    }

    func saveUnlockedBadge(_ badge: AchievementBadge, earnedAt: Date = Date()) async throws {
        guard let userID = currentUser?.id.uuidString else { return }

        let data = UserBadgeData(
            userId: userID,
            badgeId: badge.rawValue,
            badgeName: badge.title,
            earnedAt: earnedAt
        )

        try await configuredClient()
            .from("user_badges")
            .upsert(data, onConflict: "user_id,badge_id")
            .execute()
    }

    func fetchUnlockedBadges(userId: String) async throws -> Set<AchievementBadge> {
        let response: PostgrestResponse<[UserBadgeData]> = try await configuredClient()
            .from("user_badges")
            .select()
            .eq("user_id", value: userId)
            .execute()

        return Set(response.value.compactMap { AchievementBadge(rawValue: $0.badgeId) })
    }

    func saveAchievementProgress(_ state: AchievementProgressState) async throws {
        guard let userID = currentUser?.id.uuidString else { return }

        let data = UserAchievementProgressData(
            userId: userID,
            totalSavedWords: max(state.totalSavedWords, state.savedWordIDs.count),
            savedWordIDs: Array(state.savedWordIDs).sorted(),
            perfectPracticeCount: state.perfectPracticeCount,
            perfectNewsQuizCount: state.perfectNewsQuizCount,
            hasCompletedEarlyBirdLesson: state.hasCompletedEarlyBirdLesson,
            hasCompletedNightOwlLesson: state.hasCompletedNightOwlLesson,
            lookedUpWordIDs: Array(state.lookedUpWordIDs).sorted(),
            dailyPointActivity: state.dailyPointActivity
        )

        try await configuredClient()
            .from("user_achievement_progress")
            .upsert(data)
            .execute()
    }

    func fetchAchievementProgress(userId: String) async throws -> AchievementProgressState? {
        do {
            let response: PostgrestResponse<UserAchievementProgressData> = try await configuredClient()
                .from("user_achievement_progress")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()

            return response.value.state
        } catch {
            return nil
        }
    }

    func syncUserData(progress: UserProgress) async {
        do {
            try await saveUserProgress(progress)
        } catch {
            print("Failed to sync user progress: \(error.localizedDescription)")
        }
    }

    private func configuredClient() throws -> SupabaseClient {
        guard let client else {
            throw AuthValidationError.missingSupabaseConfiguration(
                authError ?? "Supabase is not configured."
            )
        }
        return client
    }
}

struct UserProfile: Codable {
    let id: String
    let email: String
    let displayName: String
    let createdAt: Date?
    let updatedAt: Date?

    init(
        id: String,
        email: String,
        displayName: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserProgressData: Codable {
    let userId: String
    var xp: Int
    var level: Int
    var streakDays: Int
    var hearts: Int
    var maxHearts: Int
    var lingots: Int
    var lastActiveDate: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case xp, level, hearts, lingots
        case streakDays = "streak_days"
        case maxHearts = "max_hearts"
        case lastActiveDate = "last_active_date"
    }
}

struct OnboardingSurveyData: Codable {
    let userId: String
    let learningGoal: String
    let englishLevel: String
    let dailyStudyMinutes: Int
    let biggestChallenge: String
    let submittedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case learningGoal = "learning_goal"
        case englishLevel = "english_level"
        case dailyStudyMinutes = "daily_study_minutes"
        case biggestChallenge = "biggest_challenge"
        case submittedAt = "submitted_at"
    }
}

struct SavedWordData: Codable {
    let userId: String
    let wordId: String
    let word: String
    let pronunciation: String
    let partOfSpeech: String
    let meaning: String
    let example: String
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case wordId = "word_id"
        case word, pronunciation, meaning, example
        case partOfSpeech = "part_of_speech"
        case savedAt = "saved_at"
    }
}

struct LessonResultData: Codable {
    let id: String
    let userId: String
    let lessonType: String
    let xpEarned: Int
    let lingotsEarned: Int
    let completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case lessonType = "lesson_type"
        case xpEarned = "xp_earned"
        case lingotsEarned = "lingots_earned"
        case completedAt = "completed_at"
    }
}

struct UserBadgeData: Codable {
    let userId: String
    let badgeId: String
    let badgeName: String
    let earnedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case badgeId = "badge_id"
        case badgeName = "badge_name"
        case earnedAt = "earned_at"
    }
}

struct UserAchievementProgressData: Codable {
    let userId: String
    let totalSavedWords: Int
    let savedWordIDs: [String]
    let perfectPracticeCount: Int
    let perfectNewsQuizCount: Int
    let hasCompletedEarlyBirdLesson: Bool
    let hasCompletedNightOwlLesson: Bool
    let lookedUpWordIDs: [String]
    let dailyPointActivity: [String: Int]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalSavedWords = "total_saved_words"
        case savedWordIDs = "saved_word_ids"
        case perfectPracticeCount = "perfect_practice_count"
        case perfectNewsQuizCount = "perfect_news_quiz_count"
        case hasCompletedEarlyBirdLesson = "has_completed_early_bird_lesson"
        case hasCompletedNightOwlLesson = "has_completed_night_owl_lesson"
        case lookedUpWordIDs = "looked_up_word_ids"
        case dailyPointActivity = "daily_point_activity"
    }

    var state: AchievementProgressState {
        AchievementProgressState(
            totalSavedWords: max(totalSavedWords, savedWordIDs.count),
            savedWordIDs: Set(savedWordIDs),
            perfectPracticeCount: perfectPracticeCount,
            perfectNewsQuizCount: perfectNewsQuizCount,
            hasCompletedEarlyBirdLesson: hasCompletedEarlyBirdLesson,
            hasCompletedNightOwlLesson: hasCompletedNightOwlLesson,
            lookedUpWordIDs: Set(lookedUpWordIDs),
            dailyPointActivity: dailyPointActivity
        )
    }
}

typealias UserInfo = Supabase.User
