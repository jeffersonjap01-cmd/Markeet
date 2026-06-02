import FirebaseFirestore
import Foundation

final class ReportService {
    static let shared = ReportService()

    private let db = Firestore.firestore()

    private init() {}

    func fetchReportedPosts() async throws -> [AdminReportedPostModel] {
        let posts = try await PostService.shared.fetchPosts()
            .filter { $0.reportCount > 0 }

        var reportedPosts: [AdminReportedPostModel] = []

        for post in posts {
            let reports = try await fetchReports(targetId: post.postId, targetType: .post)
            let author = try? await UserService.shared.fetchUser(uid: post.authorId)

            reportedPosts.append(
                AdminReportedPostModel(
                    post: post,
                    author: author,
                    reports: reports
                )
            )
        }

        return reportedPosts
    }

    func approveReports(for postId: String) async throws {
        try await updateReports(for: postId, status: .accepted)
    }

    func rejectReports(for postId: String) async throws {
        try await updateReports(for: postId, status: .rejected)
    }

    func dismissReports(for postId: String) async throws {
        try await updateReports(for: postId, status: .rejected)
        try await db.collection(FirestoreCollections.posts)
            .document(postId)
            .updateData(["reportCount": 0])
    }

    func deleteReportedPost(postId: String) async throws {
        try await PostService.shared.deletePost(postId: postId)
        try await approveReports(for: postId)
    }

    private func fetchReports(targetId: String, targetType: ReportTargetType) async throws -> [ReportModel] {
        let snapshot = try await db.collection(FirestoreCollections.reports)
            .whereField("targetId", isEqualTo: targetId)
            .whereField("targetType", isEqualTo: targetType.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.map { document in
            decode(id: document.documentID, data: document.data())
        }
    }

    private func updateReports(for postId: String, status: ReportStatus) async throws {
        let reports = try await fetchReports(targetId: postId, targetType: .post)
        let batch = db.batch()

        for report in reports {
            batch.updateData([
                "status": status.rawValue
            ], forDocument: db.collection(FirestoreCollections.reports).document(report.reportId))
        }

        try await batch.commit()
    }

    private func decode(id: String, data: [String: Any]) -> ReportModel {
        ReportModel(
            reportId: data.string("reportId", default: id),
            reporterId: data.string("reporterId"),
            targetId: data.string("targetId"),
            targetType: ReportTargetType(rawValue: data.string("targetType")) ?? .post,
            reason: data.string("reason"),
            status: ReportStatus(rawValue: data.string("status")) ?? .pending,
            createdAt: data.date("createdAt")
        )
    }
}
