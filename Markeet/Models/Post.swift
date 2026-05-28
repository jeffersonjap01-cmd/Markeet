import Foundation

struct Post: Identifiable {

    let id = UUID()

    var initials: String
    var username: String
    var role: String
    var time: String
    var content: String
    var likes: Int
    var comments: Int

    var isMine: Bool
}
