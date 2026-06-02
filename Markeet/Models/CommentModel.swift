import Foundation

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
