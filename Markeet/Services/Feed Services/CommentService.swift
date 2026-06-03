import FirebaseFirestore
import Foundation

/// Handles `post_comments` Firestore documents for global discussion posts.
/// Comment counts are denormalized onto `posts.commentCount` for faster feed rendering.
final class CommentService {

    static let shared = CommentService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Create and Fetch

    /// Creates a comment and increments the parent post's comment counter.
    func createComment(
        postId: String,
        userId: String,
        userName: String,
        content: String
    ) async throws {

        let commentId = UUID().uuidString

        let data: [String: Any] = [
            "commentId": commentId,
            "postId": postId,
            "userId": userId,
            "userName": userName,
            "content": content,
            "likeCount": 0,
            "createdAt": Timestamp(date: Date()),
            "deleted": false
        ]

        try await db
            .collection(FirestoreCollections.postComments)
            .document(commentId)
            .setData(data)

        try await db
            .collection(FirestoreCollections.posts)
            .document(postId)
            .updateData([
                "commentCount": FieldValue.increment(Int64(1))
            ])
    }

    func fetchComments(
        postId: String
    ) async throws -> [CommentModel] {

        let snapshot = try await db
            .collection(FirestoreCollections.postComments)
            .whereField("postId", isEqualTo: postId)
            .getDocuments()

        return snapshot.documents.compactMap { document in

            let data = document.data()

            return CommentModel(
                commentId: data["commentId"] as? String ?? document.documentID,
                postId: data["postId"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                userName: data["userName"] as? String ?? "Unknown User",
                content: data["content"] as? String ?? "",
                likeCount: data["likeCount"] as? Int ?? 0,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                deleted: data["deleted"] as? Bool ?? false
            )
        }
    }

    // MARK: - Soft Delete

    /// Marks a comment as deleted and updates the parent post counter.
    func deleteComment(
        commentId: String,
        postId: String
    ) async throws {

        try await db
            .collection(FirestoreCollections.postComments)
            .document(commentId)
            .updateData([
                "deleted": true
            ])

        try await db
            .collection(FirestoreCollections.posts)
            .document(postId)
            .updateData([
                "commentCount": FieldValue.increment(Int64(-1))
            ])
    }
}
