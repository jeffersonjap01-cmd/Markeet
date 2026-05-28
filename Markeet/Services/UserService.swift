import FirebaseFirestore
import Foundation

final class UserService {
    static let shared = UserService()

    private let db = Firestore.firestore()

    private init() {}

    func createUserProfile(uid: String, fullName: String, email: String) async throws -> UserModel {
        let now = Date()
        let user = UserModel(
            uid: uid,
            fullName: fullName,
            email: email,
            role: .defaultUser,
            profileImageURL: nil,
            bio: "",
            createdAt: now,
            onboardingStartDate: now,
            onboardingEndDate: now.addingDays(AppConstants.onboardingDays),
            onboardingActive: true,
            assignedCommunities: [],
            savedMaterials: [],
            registeredEvents: [],
            bannedStatus: false,
            fcmToken: nil
        )

        try await userDocument(uid).setData(encode(user), merge: false)
        return user
    }

    func fetchUser(uid: String) async throws -> UserModel {
        let snapshot = try await userDocument(uid).getDocument()
        guard let data = snapshot.data() else {
            throw UserServiceError.userNotFound
        }
        return decode(uid: uid, data: data)
    }

    func updateProfile(uid: String, fullName: String, bio: String, profileImageURL: String?) async throws {
        var data: [String: Any] = [
            "fullName": fullName,
            "bio": bio
        ]

        if let profileImageURL {
            data["profileImageURL"] = profileImageURL
        }

        try await userDocument(uid).updateData(data)
    }

    func deactivateOnboarding(uid: String) async throws {
        try await userDocument(uid).updateData(["onboardingActive": false])
    }

    func saveMaterial(uid: String, materialId: String) async throws {
        try await userDocument(uid).updateData([
            "savedMaterials": FieldValue.arrayUnion([materialId])
        ])
    }

    func unsaveMaterial(uid: String, materialId: String) async throws {
        try await userDocument(uid).updateData([
            "savedMaterials": FieldValue.arrayRemove([materialId])
        ])
    }

    func updateFCMToken(uid: String, token: String) async throws {
        try await userDocument(uid).updateData(["fcmToken": token])
    }

    private func userDocument(_ uid: String) -> DocumentReference {
        db.collection(FirestoreCollections.users).document(uid)
    }

    private func encode(_ user: UserModel) -> [String: Any] {
        [
            "uid": user.uid,
            "fullName": user.fullName,
            "email": user.email,
            "role": user.role.rawValue,
            "profileImageURL": user.profileImageURL as Any,
            "bio": user.bio,
            "createdAt": Timestamp(date: user.createdAt),
            "onboardingStartDate": Timestamp(date: user.onboardingStartDate),
            "onboardingEndDate": Timestamp(date: user.onboardingEndDate),
            "onboardingActive": user.onboardingActive,
            "assignedCommunities": user.assignedCommunities,
            "savedMaterials": user.savedMaterials,
            "registeredEvents": user.registeredEvents,
            "bannedStatus": user.bannedStatus,
            "fcmToken": user.fcmToken as Any
        ]
    }

    private func decode(uid: String, data: [String: Any]) -> UserModel {
        UserModel(
            uid: data.string("uid", default: uid),
            fullName: data.string("fullName"),
            email: data.string("email"),
            role: UserRole(rawValue: data.string("role")) ?? .defaultUser,
            profileImageURL: data["profileImageURL"] as? String,
            bio: data.string("bio"),
            createdAt: data.date("createdAt"),
            onboardingStartDate: data.date("onboardingStartDate"),
            onboardingEndDate: data.date("onboardingEndDate"),
            onboardingActive: data.bool("onboardingActive"),
            assignedCommunities: data.stringArray("assignedCommunities"),
            savedMaterials: data.stringArray("savedMaterials"),
            registeredEvents: data.stringArray("registeredEvents"),
            bannedStatus: data.bool("bannedStatus"),
            fcmToken: data["fcmToken"] as? String
        )
    }
}

enum UserServiceError: LocalizedError {
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            "User profile was not found in Firestore."
        }
    }
}
