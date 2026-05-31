import Auth
import Foundation
import GoogleSignIn
import Supabase
#if canImport(UIKit)
import UIKit
#endif

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
    func signInWithGoogle() async throws -> Session
    func updateProfile(displayName: String, avatarStyle: EngifyAvatarStyle) async throws -> UserInfo
    func signOut() async throws
    func deleteAccount() async throws
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

    func signInWithGoogle() async throws -> Session {
        let client = try configuredClient()
        let presentingViewController = try rootViewController()

        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

        guard let idToken = signInResult.user.idToken?.tokenString, !idToken.isEmpty else {
            throw AuthValidationError.invalidSignInCredentials("Google ID token is missing.")
        }

        let accessToken = signInResult.user.accessToken.tokenString

        return try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
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

    func deleteAccount() async throws {
        let client = try configuredClient()
        do {
            try await client.rpc("delete_my_account").execute()
        } catch {
            throw mapAccountDeletionError(error)
        }
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

    private func mapAccountDeletionError(_ error: Error) -> Error {
        let message = error.localizedDescription.lowercased()

        if message.contains("delete_my_account") && message.contains("function") {
            return AuthValidationError.accountDeletionUnavailable(
                "Account deletion is not enabled in Supabase yet. Run the latest delete-account SQL in Supabase, then try again."
            )
        }

        if message.contains("permission denied") || message.contains("auth.users") {
            return AuthValidationError.accountDeletionUnavailable(
                "Supabase blocked account deletion. Re-run the updated delete-account SQL so the function can delete from auth.users."
            )
        }

        return error
    }

    #if canImport(UIKit)
    @MainActor
    private func rootViewController() throws -> UIViewController {
        let connectedScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let keyWindow = connectedScenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        guard let rootViewController = keyWindow?.rootViewController else {
            throw AuthValidationError.invalidSignInCredentials("Unable to present Google Sign-In.")
        }

        return topViewController(from: rootViewController)
    }

    @MainActor
    private func topViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topViewController(from: presented)
        }

        if let navigation = viewController as? UINavigationController,
           let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }

        if let tab = viewController as? UITabBarController,
           let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }

        return viewController
    }
    #endif
}
