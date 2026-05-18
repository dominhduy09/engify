import Foundation

struct SignInCredentials {
    let email: String
    let password: String
}

struct SignUpCredentials {
    let email: String
    let password: String
    let displayName: String
}

struct ProfileUpdatePayload {
    let displayName: String
    let avatarStyle: EngifyAvatarStyle
}

enum AuthValidationError: LocalizedError {
    case emptyEmail
    case invalidEmail
    case weakPassword
    case emptyDisplayName
    case shortDisplayName
    case longDisplayName
    case passwordsDoNotMatch
    case missingSupabaseConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .emptyEmail:
            return "Please enter your email address."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .emptyDisplayName:
            return "Please enter your name."
        case .shortDisplayName:
            return "Name must be at least 2 characters."
        case .longDisplayName:
            return "Name must be 40 characters or less."
        case .passwordsDoNotMatch:
            return "Passwords don't match. Try again!"
        case let .missingSupabaseConfiguration(message):
            return message
        }
    }
}

enum AuthValidator {
    static func validateSignIn(email: String, password: String) throws -> SignInCredentials {
        let normalizedEmail = normalizedEmail(email)
        guard !normalizedEmail.isEmpty else {
            throw AuthValidationError.emptyEmail
        }
        guard normalizedEmail.contains("@") else {
            throw AuthValidationError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthValidationError.weakPassword
        }

        return SignInCredentials(email: normalizedEmail, password: password)
    }

    static func validateSignUp(
        email: String,
        password: String,
        confirmPassword: String,
        displayName: String
    ) throws -> SignUpCredentials {
        let credentials = try validateSignIn(email: email, password: password)
        let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedName.isEmpty else {
            throw AuthValidationError.emptyDisplayName
        }
        guard normalizedName.count >= 2 else {
            throw AuthValidationError.shortDisplayName
        }
        guard password == confirmPassword else {
            throw AuthValidationError.passwordsDoNotMatch
        }

        return SignUpCredentials(
            email: credentials.email,
            password: credentials.password,
            displayName: normalizedName
        )
    }

    static func validatePasswordReset(email: String) throws -> String {
        let normalizedEmail = normalizedEmail(email)
        guard !normalizedEmail.isEmpty else {
            throw AuthValidationError.emptyEmail
        }
        guard normalizedEmail.contains("@") else {
            throw AuthValidationError.invalidEmail
        }
        return normalizedEmail
    }

    static func validateProfileUpdate(
        displayName: String,
        avatarStyle: EngifyAvatarStyle
    ) throws -> ProfileUpdatePayload {
        let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedName.isEmpty else {
            throw AuthValidationError.emptyDisplayName
        }
        guard normalizedName.count >= 2 else {
            throw AuthValidationError.shortDisplayName
        }
        guard normalizedName.count <= 40 else {
            throw AuthValidationError.longDisplayName
        }

        return ProfileUpdatePayload(
            displayName: normalizedName,
            avatarStyle: avatarStyle
        )
    }

    private static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
