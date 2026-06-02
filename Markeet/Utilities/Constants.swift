import Foundation

enum FirestoreCollections {
    static let users = "users"
    static let posts = "posts"
    static let comments = "comments"
    static let likes = "likes"
    static let commentLikes = "commentLikes"
    static let news = "news"
    static let materials = "materials"
    static let groups = "groups"
    static let chats = "chats"
    static let messages = "messages"
    static let reports = "reports"
    static let events = "events"
    static let notifications = "notifications"
}

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

enum AppConstants {
    static let onboardingDays = 7
    static let maxJoinedCommunities = 5
    static let maxGroupMembers = 15
    static let minGroupMembers = 5
    static let maxGroupMentors = 3
    static let minGroupMentors = 1
}
