import FirebaseFirestore
import Foundation

final class AdminBootstrapService {
    static let shared = AdminBootstrapService()

    private let db = Firestore.firestore()

    private init() {}

    func bootstrapCurrentUserAsFirstAdmin(uid: String) async throws {
        guard try await hasNoAdminUsers() else {
            throw AdminBootstrapError.adminAlreadyExists
        }

        try await UserService.shared.updateRole(uid: uid, role: .admin)
    }

    func promoteExistingUserToAdmin(email: String) async throws -> UserModel {
        guard try await hasNoAdminUsers() else {
            throw AdminBootstrapError.adminAlreadyExists
        }

        var user = try await UserService.shared.fetchUser(email: email)
        try await UserService.shared.updateRole(uid: user.uid, role: .admin)
        user.role = .admin
        return user
    }

    private func hasNoAdminUsers() async throws -> Bool {
        let snapshot = try await db.collection(FirestoreCollections.users)
            .whereField("role", isEqualTo: UserRole.admin.rawValue)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.isEmpty
    }
}

enum AdminBootstrapError: LocalizedError {
    case adminAlreadyExists

    var errorDescription: String? {
        switch self {
        case .adminAlreadyExists:
            "An admin account already exists. Use the admin role management screen for further role changes."
        }
    }
}
