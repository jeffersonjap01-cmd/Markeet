import Foundation

enum ChatType: String, Codable {
    case group
    case mentor
    case admin
}

struct MessageModel: Identifiable, Equatable {
    let messageId: String
    var id: String { messageId }
    var senderId: String
    var content: String
    var createdAt: Date
    var deleted: Bool
}
