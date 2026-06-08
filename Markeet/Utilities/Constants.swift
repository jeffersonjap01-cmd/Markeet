import Foundation

/// Central list of Firestore collection names used by services.
/// Keeping names here avoids accidental mismatches such as `likes` vs `post_likes`.
enum FirestoreCollections {
    static let users = "users"
    static let posts = "posts"
    static let postComments = "post_comments"
    static let postLikes = "post_likes"
    static let postCommentLikes = "post_comment_likes"
    static let news = "news"
    static let materials = "materials"
    static let groups = "groups"
    static let activities = "activities"
    static let activityAssignments = "activity_assignments"
    static let chats = "chats"
    static let messages = "messages"
    static let reports = "reports"
    static let events = "events"
    static let eventRegistrations = "event_registrations"
    static let moderationLogs = "moderationLogs"
}

/// Firebase Storage path helpers.
/// Only profile image upload is currently implemented; material paths are kept
enum StoragePaths {
    static func profileImage(uid: String) -> String {
        "profileImages/\(uid)/profile.jpg"
    }

    static func materialThumbnail(materialId: String) -> String {
        "materials/\(materialId)/thumbnail.jpg"
    }

    static func materialContent(materialId: String, fileName: String) -> String {
        "materials/\(materialId)/\(fileName)"
    }
}

/// Product-wide business constants.
/// Community and mentor limits are enforced in services and mirrored in UI validation.
enum AppConstants {
    static let onboardingDays = 7
    static let maxJoinedCommunities = 5
    static let maxGroupMembers = 15
    static let minGroupMembers = 5
    static let maxGroupMentors = 3
    static let minGroupMentors = 1
    static let maxMentorCommunities = 5

    static let marketingInterests = [
        "Digital Marketing",
        "Social Media Marketing",
        "Content Marketing",
        "SEO",
        "SEM",
        "Branding",
        "Marketing Analytics",
        "Influencer Marketing",
        "E-Commerce Marketing",
        "Email Marketing"
    ]
}
