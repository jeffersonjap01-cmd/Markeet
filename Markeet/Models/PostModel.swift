import Foundation

/// Firestore-backed global discussion post.
/// Posts are soft-deleted with `deleted = true` so moderation/report history can
/// remain consistent while the feed hides removed content.
struct PostModel: Identifiable, Equatable {
    let postId: String
    var id: String { postId }
    var authorId: String
    var content: String
    var imageURL: String?
    var likeCount: Int
    var commentCount: Int
    var reportCount: Int
    var createdAt: Date
    var deleted: Bool
}
