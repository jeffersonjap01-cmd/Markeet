import Foundation

struct CommentModel: Identifiable, Equatable {
    let commentId: String
    var id: String { commentId }
    var authorId: String
    var content: String
    var createdAt: Date
    var deleted: Bool
}
