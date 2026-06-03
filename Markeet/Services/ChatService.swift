import FirebaseFirestore
import Foundation

/// Realtime Firestore service for community chat.
/// Messages are stored under `chats/{groupId}/messages`, where `groupId` is the
/// same id as the community document.
final class ChatService {
    static let shared = ChatService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Realtime Listening

    func listenToMessages(groupId: String, onChange: @escaping ([MessageModel]) -> Void) -> ListenerRegistration {
        messagesCollection(groupId: groupId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap { document in
                    self.decode(id: document.documentID, data: document.data())
                } ?? []
                onChange(messages.filter { !$0.deleted })
            }
    }

    // MARK: - Sending Messages

    func sendMessage(groupId: String, senderId: String, senderName: String, content: String) async throws {
        let messageId = UUID().uuidString
        let data: [String: Any] = [
            "messageId": messageId,
            "senderId": senderId,
            "senderName": senderName,
            "content": content,
            "createdAt": Timestamp(date: Date()),
            "deleted": false
        ]

        try await messagesCollection(groupId: groupId)
            .document(messageId)
            .setData(data)
    }

    // MARK: - Firestore Mapping

    private func messagesCollection(groupId: String) -> CollectionReference {
        db.collection(FirestoreCollections.chats)
            .document(groupId)
            .collection(FirestoreCollections.messages)
    }

    private func decode(id: String, data: [String: Any]) -> MessageModel {
        MessageModel(
            messageId: data.string("messageId", default: id),
            senderId: data.string("senderId"),
            senderName: data.string("senderName", default: "Unknown"),
            content: data.string("content"),
            createdAt: data.date("createdAt"),
            deleted: data.bool("deleted")
        )
    }
}
