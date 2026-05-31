import Auth
import Combine
import Foundation

enum AuthenticationState: Equatable {
    case restoring
    case authenticated
    case unauthenticated
}

enum GuestLockedFeature {
    case vocabulary
    case practice
    case dictionaryLimit
    case newsLimit
    case saveWords
    case accountMenu

    var reason: String {
        switch self {
        case .vocabulary:
            return "Vocabulary lessons stay locked in guest mode because saved study progress needs an account."
        case .practice:
            return "Practice workouts stay locked in guest mode so your speaking history, quiz results, and streaks can be saved."
        case .dictionaryLimit:
            return "Guest mode includes three dictionary searches per session. Sign in to keep looking up words without limits."
        case .newsLimit:
            return "Guest mode includes one free article preview. Sign in to unlock the full reading library."
        case .saveWords:
            return "Saving vocabulary requires an account so your study deck can sync across sessions."
        case .accountMenu:
            return "Sign in or create a free account to personalize your profile and keep your learning progress."
        }
    }
}

struct AccountRequiredContext: Identifiable {
    let id = UUID()
    let feature: GuestLockedFeature
}

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var authState: AuthenticationState = .restoring
    @Published private(set) var isLoading = false
    @Published private(set) var isGuestMode = false
    @Published private(set) var guestDictionarySearchCount = 0
    @Published private(set) var guestUnlockedArticleID: UUID?
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var profileUpdateMessage: String?
    @Published var accountDeletionMessage: String?
    @Published var accountRequiredContext: AccountRequiredContext?

    var isAuthenticated: Bool {
        authState == .authenticated
    }

    var canUseGuestDictionarySearch: Bool {
        guestDictionarySearchCount < 3
    }

    var guestDictionarySearchesRemaining: Int {
        max(0, 3 - guestDictionarySearchCount)
    }

    var isSupabaseConfigured: Bool {
        authService.isConfigured
    }

    var configurationErrorMessage: String? {
        authService.configurationErrorMessage
    }

    private let authService: AuthServicing
    private let savedWordsManager: SavedWordsManager
    private let gamificationManager: GamificationManager
    private var authStateTask: Task<Void, Never>?

    init(
        authService: AuthServicing? = nil,
        savedWordsManager: SavedWordsManager,
        gamificationManager: GamificationManager
    ) {
        self.authService = authService ?? SupabaseAuthService(
            provider: .shared,
            profileService: .shared
        )
        self.savedWordsManager = savedWordsManager
        self.gamificationManager = gamificationManager
        restoreInitialState()
        observeAuthStateChanges()
    }

    deinit {
        authStateTask?.cancel()
    }

    func signIn(email: String, password: String) async -> Bool {
        do {
            let credentials = try AuthValidator.validateSignIn(email: email, password: password)
            resetMessages()
            isLoading = true
            defer { isLoading = false }

            let session = try await authService.signIn(
                email: credentials.email,
                password: credentials.password
            )
            apply(session: session)
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    func signUp(email: String, password: String, confirmPassword: String, displayName: String) async -> Bool {
        do {
            let credentials = try AuthValidator.validateSignUp(
                email: email,
                password: password,
                confirmPassword: confirmPassword,
                displayName: displayName
            )
            resetMessages()
            isLoading = true
            defer { isLoading = false }

            let result = try await authService.signUp(
                email: credentials.email,
                password: credentials.password,
                displayName: credentials.displayName
            )

            switch result {
            case let .authenticated(session):
                apply(session: session)
            case let .pendingEmailConfirmation(email):
                authState = .unauthenticated
                infoMessage = "Account created for \(email). Check your inbox to confirm your email before logging in."
            }

            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    func signInWithGoogle() async -> Bool {
        resetMessages()
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await authService.signInWithGoogle()
            apply(session: session)
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    func signOut() async {
        resetMessages()
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signOut()
        } catch {
            errorMessage = friendlyError(error)
        }

        clearSession()
    }

    func continueAsGuest() {
        resetMessages()
        clearGuestUsage()
        currentUser = nil
        authState = .unauthenticated
        isGuestMode = true
    }

    func endGuestModeAndShowAuth(message: String? = nil) {
        clearGuestUsage()
        isGuestMode = false
        authState = .unauthenticated
        currentUser = nil
        accountRequiredContext = nil
        if let message {
            infoMessage = message
        }
    }

    func presentAccountRequired(for feature: GuestLockedFeature) {
        accountRequiredContext = AccountRequiredContext(feature: feature)
    }

    func dismissAccountRequired() {
        accountRequiredContext = nil
    }

    func requestGuestDictionarySearch() -> Bool {
        guard isGuestMode else { return true }
        guard guestDictionarySearchCount < 3 else {
            presentAccountRequired(for: .dictionaryLimit)
            return false
        }

        guestDictionarySearchCount += 1
        return true
    }

    func requestGuestNewsArticleAccess(articleID: UUID) -> Bool {
        guard isGuestMode else { return true }

        if let unlockedArticleID = guestUnlockedArticleID {
            guard unlockedArticleID == articleID else {
                presentAccountRequired(for: .newsLimit)
                return false
            }
            return true
        }

        guestUnlockedArticleID = articleID
        return true
    }

    func updateProfile(displayName: String, avatarStyle: EngifyAvatarStyle) async -> Bool {
        do {
            let payload = try AuthValidator.validateProfileUpdate(
                displayName: displayName,
                avatarStyle: avatarStyle
            )
            resetMessages()
            isLoading = true
            defer { isLoading = false }

            let updatedUser = try await authService.updateProfile(
                displayName: payload.displayName,
                avatarStyle: payload.avatarStyle
            )
            currentUser = mapUser(updatedUser)
            authState = .authenticated
            profileUpdateMessage = "Profile updated."
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    func sendPasswordReset(email: String) async -> Bool {
        do {
            let validatedEmail = try AuthValidator.validatePasswordReset(email: email)
            resetMessages()
            isLoading = true
            defer { isLoading = false }

            try await authService.sendPasswordReset(email: validatedEmail)
            infoMessage = "Password reset email sent to \(validatedEmail)."
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    func deleteAccount() async -> Bool {
        resetMessages()
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.deleteAccount()
            accountDeletionMessage = "Your account has been permanently deleted."
            clearSession()
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    func consumeInfoMessage() -> String? {
        defer { infoMessage = nil }
        return infoMessage
    }

    func clearError() {
        errorMessage = nil
    }

    func consumeProfileUpdateMessage() -> String? {
        defer { profileUpdateMessage = nil }
        return profileUpdateMessage
    }

    private func restoreInitialState() {
        if let session = authService.currentSession {
            apply(session: session)
        } else {
            authState = .unauthenticated
        }
    }

    private func observeAuthStateChanges() {
        authStateTask = Task { [weak self] in
            guard let self else { return }

            for await (event, session) in authService.authStateChanges {
                guard !Task.isCancelled else { return }

                switch event {
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                    if let session {
                        apply(session: session)
                    } else {
                        clearSession()
                    }
                case .signedOut:
                    clearSession()
                case .passwordRecovery:
                    infoMessage = "Password recovery session detected. Please update your password."
                    if let session {
                        apply(session: session)
                    }
                default:
                    break
                }
            }
        }
    }

    private func apply(session: Session) {
        currentUser = mapUser(session.user)
        authState = .authenticated
        isGuestMode = false
        clearGuestUsage()
        errorMessage = nil

        let userID = session.user.id.uuidString
        Task {
            await savedWordsManager.loadFromRemote(for: userID)
            await gamificationManager.loadFromRemote(for: userID)
        }
    }

    private func clearSession() {
        currentUser = nil
        authState = .unauthenticated
        isGuestMode = false
        clearGuestUsage()
        savedWordsManager.clearRemoteSession()
        gamificationManager.clearRemoteSession()
    }

    private func mapUser(_ user: UserInfo) -> User {
        User(
            id: user.id,
            email: user.email ?? "",
            displayName: displayName(from: user),
            avatarStyle: avatarStyle(from: user)
        )
    }

    private func displayName(from user: UserInfo) -> String {
        if let displayName = user.userMetadata["display_name"]?.stringValue, !displayName.isEmpty {
            return displayName
        }

        if let fullName = user.userMetadata["full_name"]?.stringValue, !fullName.isEmpty {
            return fullName
        }

        if let email = user.email, let prefix = email.split(separator: "@").first {
            return String(prefix)
        }

        return "Learner"
    }

    private func avatarStyle(from user: UserInfo) -> EngifyAvatarStyle {
        guard
            let rawValue = user.userMetadata["avatar_style"]?.stringValue,
            let style = EngifyAvatarStyle(rawValue: rawValue)
        else {
            return .meadow
        }

        return style
    }

    private func resetMessages() {
        errorMessage = nil
        infoMessage = nil
        profileUpdateMessage = nil
        accountDeletionMessage = nil
    }

    private func clearGuestUsage() {
        guestDictionarySearchCount = 0
        guestUnlockedArticleID = nil
        accountRequiredContext = nil
    }

    private func friendlyError(_ error: Error) -> String {
        if let validationError = error as? AuthValidationError {
            return validationError.localizedDescription
        }

        let message = error.localizedDescription.lowercased()

        if message.contains("email") && message.contains("already") {
            return "An account with this email already exists. Try logging in instead."
        }
        if message.contains("invalid login credentials") {
            return "Email or password is incorrect. Please try again."
        }
        if message.contains("email not confirmed") {
            return "Please confirm your email before signing in."
        }
        if message.contains("network") || message.contains("connection") {
            return "Connection issue. Check your internet and try again."
        }
        if message.contains("rate") || message.contains("too many") {
            return "Too many attempts. Please wait a moment before trying again."
        }

        return error.localizedDescription
    }
}

private extension AnyJSON {
    var stringValue: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }
}
