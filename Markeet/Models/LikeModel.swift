import Foundation

/// Top-level Firestore like document for a post.
/// The document id is generated as `postId_userId` to make duplicate likes easy
/// to prevent and to support quick "has this user liked it?" checks.
struct LikeModel: Identifiable, Equatable {

    let likeId: String
    var id: String { likeId }

    var postId: String
    var userId: String

    var createdAt: Date
}
