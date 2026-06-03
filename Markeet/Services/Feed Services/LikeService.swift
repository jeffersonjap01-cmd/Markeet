import FirebaseFirestore
import Foundation

/// Handles post likes in the top-level `post_likes` collection.
/// The like document id is deterministic (`postId_userId`) to prevent duplicates.
final class LikeService {

    static let shared = LikeService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Like Mutations

    func likePost(
        postId: String,
        userId: String
    ) async throws {

        let likeId = "\(postId)_\(userId)"

        let data: [String: Any] = [
            "likeId": likeId,
            "postId": postId,
            "userId": userId,
            "createdAt": Timestamp(date: Date())
        ]

        try await db
            .collection(FirestoreCollections.postLikes)
            .document(likeId)
            .setData(data)

        try await db
            .collection(FirestoreCollections.posts)
            .document(postId)
            .updateData([
                "likeCount": FieldValue.increment(Int64(1))
            ])
    }

    func unlikePost(
        postId: String,
        userId: String
    ) async throws {

        let likeId = "\(postId)_\(userId)"

        try await db
            .collection(FirestoreCollections.postLikes)
            .document(likeId)
            .delete()

        try await db
            .collection(FirestoreCollections.posts)
            .document(postId)
            .updateData([
                "likeCount": FieldValue.increment(Int64(-1))
            ])
    }

    // MARK: - Like Queries

    func hasLiked(
        postId: String,
        userId: String
    ) async throws -> Bool {

        let likeId = "\(postId)_\(userId)"

        let snapshot = try await db
            .collection(FirestoreCollections.postLikes)
            .document(likeId)
            .getDocument()

        return snapshot.exists
    }

    func fetchLikeCount(
        postId: String
    ) async throws -> Int {

        let snapshot = try await db
            .collection(FirestoreCollections.postLikes)
            .whereField("postId", isEqualTo: postId)
            .getDocuments()

        return snapshot.documents.count
    }
}
