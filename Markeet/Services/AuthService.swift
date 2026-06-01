import AuthenticationServices
import FirebaseAuth
import Foundation

final class AuthService {
    static let shared = AuthService()

    private init() {}

    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

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
