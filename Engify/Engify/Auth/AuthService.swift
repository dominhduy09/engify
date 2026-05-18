import Auth
import Foundation
import Supabase

enum AuthSignUpOutcome {
    case authenticated(Session)
    case pendingEmailConfirmation(email: String)
}

protocol AuthServicing {
    var isConfigured: Bool { get }
    var configurationErrorMessage: String? { get }
    var currentSession: Session? { get }
    var currentUser: UserInfo? { get }
    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> { get }

    func signIn(email: String, password: String) async throws -> Session
    func signUp(email: String, password: String, displayName: String) async throws -> AuthSignUpOutcome
    func updateProfile(displayName: String, avatarStyle: EngifyAvatarStyle) async throws -> UserInfo
    func signOut() async throws
    func sendPasswordReset(email: String) async throws
}

final class SupabaseAuthService: AuthServicing {
    private let provider: SupabaseClientProvider
    private let profileService: SupabaseManager

    init(provider: SupabaseClientProvider, profileService: SupabaseManager) {
        self.provider = provider
        self.profileService = profileService
    }

    var isConfigured: Bool {
        provider.client != nil
    }

    var configurationErrorMessage: String? {
        provider.configurationError?.localizedDescription
    }

    var currentSession: Session? {
        provider.client?.auth.currentSession
    }

    var currentUser: UserInfo? {
        provider.client?.auth.currentUser
    }

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        provider.client?.auth.authStateChanges ?? AsyncStream { continuation in
            continuation.yield((event: .initialSession, session: nil))
            continuation.finish()
        }
    }

    func signIn(email: String, password: String) async throws -> Session {
        let client = try configuredClient()
        return try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AuthSignUpOutcome {
        let client = try configuredClient()

        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "display_name": .string(displayName),
                "avatar_style": .string(EngifyAvatarStyle.meadow.rawValue)
            ]
        )

        try await profileService.upsertUserProfile(
            userID: response.user.id.uuidString,
            email: email,
            displayName: displayName
        )

        if let session = response.session {
            return .authenticated(session)
        }

        return .pendingEmailConfirmation(email: email)
    }

    func updateProfile(displayName: String, avatarStyle: EngifyAvatarStyle) async throws -> UserInfo {
        let client = try configuredClient()
        let updatedUser = try await client.auth.update(
            user: UserAttributes(
                data: [
                    "display_name": .string(displayName),
                    "avatar_style": .string(avatarStyle.rawValue)
                ]
            )
        )

        try await profileService.upsertUserProfile(
            userID: updatedUser.id.uuidString,
            email: updatedUser.email ?? currentUser?.email ?? "",
            displayName: displayName
        )

        return updatedUser
    }

    func signOut() async throws {
        let client = try configuredClient()
        try await client.auth.signOut()
    }

    func sendPasswordReset(email: String) async throws {
        let client = try configuredClient()
        try await client.auth.resetPasswordForEmail(email)
    }

    private func configuredClient() throws -> SupabaseClient {
        guard let client = provider.client else {
            throw AuthValidationError.missingSupabaseConfiguration(
                provider.configurationError?.localizedDescription ?? "Supabase is not configured."
            )
        }
        return client
    }
}
