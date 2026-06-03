import Foundation

/// Role values stored on each `users/{uid}` Firestore document.
/// The role drives root navigation, admin access, mentor-only community/event tools,
/// and member/default-user behavior throughout the app.
enum UserRole: String, CaseIterable, Codable, Identifiable {
    case defaultUser
    case member
    case communityUser
    case mentor
    case admin

    var id: String { rawValue }

    static var adminAssignableRoles: [UserRole] {
        [.defaultUser, .member, .mentor, .admin]
    }

    var displayName: String {
        switch self {
        case .defaultUser:
            "Default User"
        case .member:
            "Member"
        case .communityUser:
            "Community User"
        case .mentor:
            "Mentor"
        case .admin:
            "Admin"
        }
    }

    var isAdmin: Bool {
        self == .admin
    }

    var isCommunityMember: Bool {
        self == .member || self == .communityUser
    }
}

/// Firestore-backed user profile for a Firebase Authentication account.
/// The document id is the Firebase Auth `uid`, and related feature arrays store
/// lightweight ids instead of embedded documents to match Firestore best practices.
struct UserModel: Identifiable, Equatable {
    let uid: String
    var id: String { uid }
    var fullName: String
    var email: String
    var role: UserRole
    var profileImageURL: String?
    var bio: String
    var createdAt: Date
    var onboardingStartDate: Date
    var onboardingEndDate: Date
    var onboardingActive: Bool
    var marketingInterests: [String]
    var assignedCommunities: [String]
    var savedMaterials: [String]
    var registeredEvents: [String]
    var bannedStatus: Bool
    var fcmToken: String?

    /// Business rule: a user can belong to at most five communities.
    var canJoinMoreCommunities: Bool {
        assignedCommunities.count < AppConstants.maxJoinedCommunities
    }

    var isAdmin: Bool {
        role.isAdmin
    }

    var isCommunityMember: Bool {
        role.isCommunityMember || !assignedCommunities.isEmpty
    }

}
