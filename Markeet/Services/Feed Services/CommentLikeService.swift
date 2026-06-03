import FirebaseFirestore
import Foundation

/// Handles likes on comments through `post_comment_likes`.
/// Comment like counts are denormalized on the `post_comments` document.
final class CommentLikeService {

    static let shared = CommentLikeService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Comment Like Mutations

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
            .collection(FirestoreCollections.postCommentLikes)
            .document(likeId)
            .setData(data)

        try await db
            .collection(FirestoreCollections.postComments)
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
            .collection(FirestoreCollections.postCommentLikes)
            .document(likeId)
            .delete()

        try await db
            .collection(FirestoreCollections.postComments)
            .document(commentId)
            .updateData([
                "likeCount": FieldValue.increment(Int64(-1))
            ])
    }

    // MARK: - Comment Like Queries

    func hasLiked(
        commentId: String,
        userId: String
    ) async throws -> Bool {

        let likeId = "\(commentId)_\(userId)"

        let snapshot = try await db
            .collection(FirestoreCollections.postCommentLikes)
            .document(likeId)
            .getDocument()

        return snapshot.exists
    }
}
