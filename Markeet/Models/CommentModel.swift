import Foundation

/// Top-level Firestore comment document for a global discussion post.
/// Comments reference the parent post by `postId` rather than living in a post
/// subcollection; this matches the current `post_comments` collection strategy.
struct CommentModel: Identifiable, Equatable {

    let commentId: String
    var id: String { commentId }

    var postId: String

    var userId: String
    var userName: String

    var content: String

    var likeCount: Int

    var createdAt: Date
    var deleted: Bool
}
