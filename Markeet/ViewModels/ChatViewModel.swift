import FirebaseFirestore
import Foundation

/// View model for a community group chat screen.
/// It keeps the Firestore listener alive while the view is visible and sends
/// messages through `ChatService`.
@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Published State

    @Published var messages: [MessageModel] = []
    @Published var draftMessage = ""
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    // MARK: - Listener Lifecycle

    func startListening(groupId: String) {
        listener?.remove()
        listener = ChatService.shared.listenToMessages(groupId: groupId) { [weak self] messages in
            Task { @MainActor in
                self?.messages = messages
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Sending

    func send(groupId: String, session: SessionManager) async {
        let content = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, let user = session.currentUser else {
            return
        }

        do {
            try await ChatService.shared.sendMessage(
                groupId: groupId,
                senderId: user.uid,
                senderName: user.fullName,
                content: content
            )
            draftMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
