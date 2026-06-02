import FirebaseFirestore
import Foundation

final class CommentLikeService {

    static let shared = CommentLikeService()

    private let db = Firestore.firestore()

    private init() {}

    func likeComment(
        commentId: String,
        userId: String
    ) async throws {

        let likeId = "\(commentId)_\(userId)"

        let data: [String: Any] = [
            "likeId": likeId,
            "commentId": commentId,
            "userId": userId,
            "createdAt": Timestamp(date: Date())
        ]

        try await db
            .collection("commentLikes")
            .document(likeId)
            .setData(data)

        try await db
            .collection(FirestoreCollections.comments)
            .document(commentId)
            .updateData([
                "likeCount": FieldValue.increment(Int64(1))
            ])
    }

    func unlikeComment(
        commentId: String,
        userId: String
    ) async throws {

        let likeId = "\(commentId)_\(userId)"

        try await db
            .collection("commentLikes")
            .document(likeId)
            .delete()

        try await db
            .collection(FirestoreCollections.comments)
            .document(commentId)
            .updateData([
                "likeCount": FieldValue.increment(Int64(-1))
            ])
    }

    func hasLiked(
        commentId: String,
        userId: String
    ) async throws -> Bool {

        let likeId = "\(commentId)_\(userId)"

        let snapshot = try await db
            .collection("commentLikes")
            .document(likeId)
            .getDocument()

        return snapshot.exists
    }
}
