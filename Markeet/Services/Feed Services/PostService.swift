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

    func fetchPost(postId: String) async throws -> PostModel {
        let document = try await db
            .collection(FirestoreCollections.posts)
            .document(postId)
            .getDocument()

        guard let data = document.data() else {
            throw PostServiceError.postNotFound
        }

        return decodePost(id: document.documentID, data: data)
    }

    func deletePost(postId: String) async throws {

        try await db
            .collection(FirestoreCollections.posts)
            .document(postId)
            .updateData(["deleted": true])
    }

    func deleteOwnPost(postId: String, requestingUserId: String) async throws {
        guard !requestingUserId.isEmpty else {
            throw PostServiceError.missingUser
        }

        let post = try await fetchPost(postId: postId)
        guard post.authorId == requestingUserId else {
            throw PostServiceError.notPostOwner
        }

        try await deletePost(postId: postId)
    }

    func reportPost(postId: String, reporterId: String = "", reason: String = "Reported by user") async throws {
        guard !reporterId.isEmpty else {
            throw PostServiceError.missingUser
        }

        let reportId = "\(postId)_\(reporterId)"
        let postRef = db.collection(FirestoreCollections.posts).document(postId)
        let reportRef = db.collection(FirestoreCollections.reports).document(reportId)

        try await db.runVoidAsyncTransaction { transaction in
            let postSnapshot = try transaction.getDocument(postRef)
            guard let postData = postSnapshot.data() else {
                throw PostServiceError.postNotFound
            }

            guard !postData.bool("deleted") else {
                throw PostServiceError.postNotFound
            }

            guard postData.string("authorId") != reporterId else {
                throw PostServiceError.cannotReportOwnPost
            }

            let reportSnapshot = try transaction.getDocument(reportRef)
            if reportSnapshot.exists {
                let wasPending = reportSnapshot.data()?.string("status") == ReportStatus.pending.rawValue
                transaction.updateData([
                    "reason": reason,
                    "status": ReportStatus.pending.rawValue,
                    "updatedAt": Timestamp(date: Date())
                ], forDocument: reportRef)

                if !wasPending {
                    transaction.updateData([
                        "reportCount": FieldValue.increment(Int64(1))
                    ], forDocument: postRef)
                }

                return
            }

            transaction.setData([
                "reportId": reportId,
                "reporterId": reporterId,
                "targetId": postId,
                "targetType": ReportTargetType.post.rawValue,
                "reason": reason,
                "status": ReportStatus.pending.rawValue,
                "createdAt": Timestamp(date: Date())
            ], forDocument: reportRef)

            transaction.updateData([
                "reportCount": FieldValue.increment(Int64(1))
            ], forDocument: postRef)
        }
    }

    private func decodePost(id: String, data: [String: Any]) -> PostModel {
        PostModel(
            postId: data["postId"] as? String ?? id,
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

enum PostServiceError: LocalizedError {
    case missingUser
    case postNotFound
    case notPostOwner
    case cannotReportOwnPost

    var errorDescription: String? {
        switch self {
        case .missingUser:
            "User session is missing."
        case .postNotFound:
            "Post was not found."
        case .notPostOwner:
            "Only the post owner can delete this post."
        case .cannotReportOwnPost:
            "You cannot report your own post."
        }
    }
}

private extension Firestore {
    func runVoidAsyncTransaction(_ updateBlock: @escaping (Transaction) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            runTransaction({ transaction, errorPointer in
                do {
                    try updateBlock(transaction)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
}
