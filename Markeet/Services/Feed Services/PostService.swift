import FirebaseFirestore
import Foundation

final class PostService {

    static let shared = PostService()

    private let db = Firestore.firestore()

    private init() {}

    func createPost(
        authorId: String,
        content: String
    ) async throws {

        let postId = UUID().uuidString

        let data: [String: Any] = [
            "postId": postId,
            "authorId": authorId,
            "content": content,
            "imageURL": NSNull(),
            "likeCount": 0,
            "commentCount": 0,
            "reportCount": 0,
            "createdAt": Timestamp(date: Date()),
            "deleted": false
        ]

        try await db
            .collection("posts")
            .document(postId)
            .setData(data)
    }

    func fetchPosts() async throws -> [PostModel] {

        let snapshot = try await db
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in

            let data = document.data()

            return PostModel(
                postId: data["postId"] as? String ?? document.documentID,
                authorId: data["authorId"] as? String ?? "",
                content: data["content"] as? String ?? "",
                imageURL: data["imageURL"] as? String,
                likeCount: data["likeCount"] as? Int ?? 0,
                commentCount: data["commentCount"] as? Int ?? 0,
                reportCount: data["reportCount"] as? Int ?? 0,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                deleted: data["deleted"] as? Bool ?? false
            )
        }
    }

    func deletePost(postId: String) async throws {

        try await db
            .collection(FirestoreCollections.posts)
            .document(postId)
            .updateData(["deleted": true])
    }

    func reportPost(postId: String, reporterId: String = "", reason: String = "Reported by user") async throws {
        let reportId = UUID().uuidString
        let batch = db.batch()
        let postRef = db.collection(FirestoreCollections.posts).document(postId)
        let reportRef = db.collection(FirestoreCollections.reports).document(reportId)

        batch.setData([
            "reportId": reportId,
            "reporterId": reporterId,
            "targetId": postId,
            "targetType": ReportTargetType.post.rawValue,
            "reason": reason,
            "status": ReportStatus.pending.rawValue,
            "createdAt": Timestamp(date: Date())
        ], forDocument: reportRef)

        batch.updateData([
            "reportCount": FieldValue.increment(Int64(1))
        ], forDocument: postRef)

        try await batch.commit()
    }
}
