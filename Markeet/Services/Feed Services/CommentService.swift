import FirebaseFirestore
import Foundation

final class CommentService {

    static let shared = CommentService()

    private let db = Firestore.firestore()

    private init() {}

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
            .collection(FirestoreCollections.comments)
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
            .collection(FirestoreCollections.comments)
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

    func deleteComment(
        commentId: String,
        postId: String
    ) async throws {

        try await db
            .collection(FirestoreCollections.comments)
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
