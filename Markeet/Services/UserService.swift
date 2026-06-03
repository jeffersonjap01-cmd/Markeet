import FirebaseFirestore
import Foundation

/// Central Firestore service for `users/{uid}` documents.
/// UserService owns profile creation, role updates, saved material ids, event ids,
/// and profile decoding used by almost every feature.
final class UserService {
    static let shared = UserService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Profile Creation

    /// Creates the Firestore profile after Firebase Auth registration.
    /// New users always start as `.defaultUser`; admin/mentor/member roles are
    /// assigned later through admin tools or community joins.
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
            marketingInterests: [],
            assignedCommunities: [],
            savedMaterials: [],
            registeredEvents: [],
            bannedStatus: false,
            fcmToken: nil
        )

        try await userDocument(uid).setData(encode(user), merge: false)
        return user
    }

    // MARK: - Reads

    func fetchUser(uid: String) async throws -> UserModel {
        let snapshot = try await userDocument(uid).getDocument()
        guard let data = snapshot.data() else {
            throw UserServiceError.userNotFound
        }
        return decode(uid: uid, data: data)
    }

    func fetchAllUsers() async throws -> [UserModel] {
        let snapshot = try await db.collection(FirestoreCollections.users)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.map { document in
            decode(uid: document.documentID, data: document.data())
        }
    }

    func fetchUser(email: String) async throws -> UserModel {
        let snapshot = try await db.collection(FirestoreCollections.users)
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            throw UserServiceError.userNotFound
        }

        return decode(uid: document.documentID, data: document.data())
    }

    // MARK: - Profile Updates

    /// Updates only user-editable profile fields. Role and membership changes
    /// are intentionally handled by separate methods to keep permissions clear.
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

    // MARK: - Role and Membership Updates

    func updateRole(uid: String, role: UserRole) async throws {
        try await userDocument(uid).updateData(["role": role.rawValue])
    }

    func assignCommunities(uid: String, communityIds: [String]) async throws {
        try await userDocument(uid).updateData(["assignedCommunities": communityIds])
    }

    // MARK: - User Preferences

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

    // MARK: - Firebase Helpers

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
            "marketingInterests": user.marketingInterests,
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
            role: decodeRole(data.string("role")),
            profileImageURL: data["profileImageURL"] as? String,
            bio: data.string("bio"),
            createdAt: data.date("createdAt"),
            onboardingStartDate: data.date("onboardingStartDate"),
            onboardingEndDate: data.date("onboardingEndDate"),
            onboardingActive: data.bool("onboardingActive"),
            marketingInterests: data.stringArray("marketingInterests"),
            assignedCommunities: data.stringArray("assignedCommunities"),
            savedMaterials: data.stringArray("savedMaterials"),
            registeredEvents: data.stringArray("registeredEvents"),
            bannedStatus: data.bool("bannedStatus"),
            fcmToken: data["fcmToken"] as? String
        )
    }

    private func decodeRole(_ rawValue: String) -> UserRole {
        switch rawValue {
        case UserRole.member.rawValue:
            .member
        case UserRole.communityUser.rawValue:
            .communityUser
        case UserRole.mentor.rawValue:
            .mentor
        case UserRole.admin.rawValue:
            .admin
        default:
            .defaultUser
        }
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
