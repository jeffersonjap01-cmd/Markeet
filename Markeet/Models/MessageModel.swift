import Foundation

/// Chat category reserved for chat routing.
/// Current community chat messages are stored under `chats/{groupId}/messages`.
enum ChatType: String, Codable {
    case group
    case mentor
    case admin
}

/// Message document in a community chat subcollection.
/// Each message stores sender display data at send time so the chat can render
/// without fetching the user profile for every bubble.
struct MessageModel: Identifiable, Equatable {
    let messageId: String
    var id: String { messageId }
    var senderId: String
    var senderName: String
    var content: String
    var createdAt: Date
    var deleted: Bool
}
