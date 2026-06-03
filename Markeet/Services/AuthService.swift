import AuthenticationServices
import FirebaseAuth
import Foundation

/// Thin wrapper around Firebase Authentication.
/// AuthService handles credential-based auth, then delegates profile creation
/// and loading to `UserService` because app roles and profile data live in Firestore.
final class AuthService {
    static let shared = AuthService()

    private init() {}

    // MARK: - Current Session

    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Email Authentication

    /// Creates the Firebase Auth account, sends verification email, and creates
    /// the matching `users/{uid}` Firestore profile with the default role.
    func register(fullName: String, email: String, password: String) async throws -> UserModel {
        try Validators.validateName(fullName)
        try Validators.validateEmail(email)
        try Validators.validatePassword(password)

        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        try await result.user.sendEmailVerification()
        return try await UserService.shared.createUserProfile(
            uid: result.user.uid,
            fullName: fullName,
            email: email
        )
    }

    /// Signs in with Firebase Auth, then loads the Firestore profile so banned
    /// users and role-based navigation can be handled immediately.
    func login(email: String, password: String) async throws -> UserModel {
        try Validators.validateEmail(email)
        try Validators.validatePassword(password)

        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = try await UserService.shared.fetchUser(uid: result.user.uid)

        if user.bannedStatus {
            try signOut()
            throw AuthServiceError.bannedUser
        }

        return user
    }

    // MARK: - Account Recovery

    func sendPasswordReset(email: String) async throws {
        try Validators.validateEmail(email)
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func resendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notSignedIn
        }
        try await user.sendEmailVerification()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Provider Authentication

    /// Supports Apple sign-in by creating a Firestore profile on first provider login.
    func signInWithApple(credential: AuthCredential) async throws -> UserModel {
        let result = try await Auth.auth().signIn(with: credential)
        return try await fetchOrCreateProviderProfile(for: result.user)
    }


    private func fetchOrCreateProviderProfile(for firebaseUser: FirebaseAuth.User) async throws -> UserModel {
        do {
            return try await UserService.shared.fetchUser(uid: firebaseUser.uid)
        } catch UserServiceError.userNotFound {
            return try await UserService.shared.createUserProfile(
                uid: firebaseUser.uid,
                fullName: firebaseUser.displayName ?? "New Member",
                email: firebaseUser.email ?? ""
            )
        }
    }
}

enum AuthServiceError: LocalizedError {
    case bannedUser
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .bannedUser:
            "This account has been banned by an admin."
        case .notSignedIn:
            "Please sign in first."
        }
    }
}
