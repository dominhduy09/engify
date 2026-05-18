import Combine
import Foundation
import Supabase

@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    let client: SupabaseClient?

    @Published private(set) var isInitialized = false
    @Published private(set) var authError: String?

    private init(provider: SupabaseClientProvider = .shared) {
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
            displayName: displayName,
            createdAt: Date()
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

    func saveUserProgress(_ progress: UserProgress) async throws {
        guard let userID = currentUser?.id.uuidString else { return }

        let data = UserProgressData(
            userId: userID,
            xp: progress.xp,
            level: progress.level,
            streakDays: progress.streakDays,
            hearts: progress.hearts,
            maxHearts: progress.maxHearts,
            lingots: progress.lingots,
            lastActiveDate: progress.lastActiveDate
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

            return UserProgress(
                xp: response.value.xp,
                level: response.value.level,
                streakDays: response.value.streakDays,
                hearts: response.value.hearts,
                maxHearts: response.value.maxHearts,
                lingots: response.value.lingots,
                lastActiveDate: response.value.lastActiveDate
            )
        } catch {
            return nil
        }
    }

    func saveWord(_ word: Word) async throws {
        guard let userID = currentUser?.id.uuidString else { return }

        let savedWord = SavedWordData(
            userId: userID,
            wordId: word.id.uuidString,
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
                id: UUID(uuidString: data.wordId) ?? UUID(),
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
    let createdAt: Date
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
        case xp, level, streakDays, hearts, maxHearts, lingots, lastActiveDate
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
        case word, pronunciation, partOfSpeech, meaning, example, savedAt
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
        case lessonType, xpEarned, lingotsEarned, completedAt
    }
}

typealias UserInfo = Supabase.User
