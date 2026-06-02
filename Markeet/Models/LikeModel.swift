import Foundation

struct LikeModel: Identifiable, Equatable {

    let likeId: String
    var id: String { likeId }

    var postId: String
    var userId: String

    var createdAt: Date
}
