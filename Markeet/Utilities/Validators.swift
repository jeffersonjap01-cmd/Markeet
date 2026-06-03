import Foundation

/// User-facing validation failures used by authentication and profile forms.
enum ValidationError: LocalizedError {
    case emptyName
    case invalidEmail
    case weakPassword
    case passwordMismatch

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "Please enter your full name."
        case .invalidEmail:
            "Please enter a valid email address."
        case .weakPassword:
            "Password must be at least 6 characters."
        case .passwordMismatch:
            "Passwords do not match."
        }
    }
}

/// Shared form validators used before calling Firebase services.
/// Keeping validation here makes error messages consistent across screens.
enum Validators {
    static func validateName(_ name: String) throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyName
        }
    }

    static func validateEmail(_ email: String) throws {
        let pattern = #"^\S+@\S+\.\S+$"#
        if email.range(of: pattern, options: .regularExpression) == nil {
            throw ValidationError.invalidEmail
        }
    }

    static func validatePassword(_ password: String) throws {
        if password.count < 6 {
            throw ValidationError.weakPassword
        }
    }

    static func validatePasswords(_ password: String, confirmation: String) throws {
        try validatePassword(password)
        if password != confirmation {
            throw ValidationError.passwordMismatch
        }
    }
}
