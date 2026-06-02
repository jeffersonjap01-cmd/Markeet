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
            .delete()
    }

    func reportPost(postId: String) async throws {

        try await db
            .collection("posts")
            .document(postId)
            .updateData([
                "reportCount": FieldValue.increment(Int64(1))
            ])
    }
}
