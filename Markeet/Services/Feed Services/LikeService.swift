import FirebaseFirestore
import Foundation

final class LikeService {

    static let shared = LikeService()

    private let db = Firestore.firestore()

    private init() {}

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
            .collection(FirestoreCollections.likes)
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
            .collection(FirestoreCollections.likes)
            .document(likeId)
            .delete()

        try await db
            .collection(FirestoreCollections.posts)
            .document(postId)
            .updateData([
                "likeCount": FieldValue.increment(Int64(-1))
            ])
    }

    func hasLiked(
        postId: String,
        userId: String
    ) async throws -> Bool {

        let likeId = "\(postId)_\(userId)"

        let snapshot = try await db
            .collection(FirestoreCollections.likes)
            .document(likeId)
            .getDocument()

        return snapshot.exists
    }

    func fetchLikeCount(
        postId: String
    ) async throws -> Int {

        let snapshot = try await db
            .collection(FirestoreCollections.likes)
            .whereField("postId", isEqualTo: postId)
            .getDocuments()

        return snapshot.documents.count
    }
}
