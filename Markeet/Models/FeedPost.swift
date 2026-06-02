import Foundation

struct FeedPost: Identifiable {

    var postId: String
    var authorId: String

    var id: String { postId }

    var initials: String
    var username: String
    var role: String

    var time: String
    var content: String

    var likes: Int
    var comments: Int

    var isMine: Bool
}
