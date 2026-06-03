import Foundation

/// Presentation model used by the feed UI.
/// It combines post data with author display information and ownership state so
/// `PostCard` can decide whether to show edit/delete/report actions.
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
