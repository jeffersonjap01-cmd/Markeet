import Foundation

enum UserRole: String, CaseIterable, Codable, Identifiable {
    case defaultUser
    case communityUser
    case mentor
    case admin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultUser:
            "Default User"
        case .communityUser:
            "Community User"
        case .mentor:
            "Mentor"
        case .admin:
            "Admin"
        }
    }
}

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
    var assignedCommunities: [String]
    var savedMaterials: [String]
    var registeredEvents: [String]
    var bannedStatus: Bool
    var fcmToken: String?

    var canUseOnboardingFeatures: Bool {
        onboardingActive && Date() <= onboardingEndDate
    }

    var canJoinMoreCommunities: Bool {
        canUseOnboardingFeatures && assignedCommunities.count < AppConstants.maxJoinedCommunities
    }
}
