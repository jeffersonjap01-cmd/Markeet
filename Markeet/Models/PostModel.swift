import Foundation

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
