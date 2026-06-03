import FirebaseFirestore
import Foundation

/// Admin moderation service for reported global discussion posts.
/// Reports are stored in `reports`; pending post reports are grouped with their
/// post and author data for the admin Reports screen.
final class ReportService {
    static let shared = ReportService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Admin Report Loading

    func fetchReportedPosts() async throws -> [AdminReportedPostModel] {
        let reports = try await fetchPostReports()
        let reportsByPostId = Dictionary(grouping: reports, by: \.targetId)

        var reportedPosts: [AdminReportedPostModel] = []

        for (postId, reports) in reportsByPostId {
            let post = try await PostService.shared.fetchPost(postId: postId)
            guard !post.deleted else {
                continue
            }

            let author = try? await UserService.shared.fetchUser(uid: post.authorId)

            reportedPosts.append(
                AdminReportedPostModel(
                    post: post,
                    author: author,
                    reports: reports.sorted { $0.createdAt > $1.createdAt }
                )
            )
        }

        return reportedPosts.sorted { lhs, rhs in
            let lhsDate = lhs.reports.map(\.createdAt).max() ?? lhs.post.createdAt
            let rhsDate = rhs.reports.map(\.createdAt).max() ?? rhs.post.createdAt
            return lhsDate > rhsDate
        }
    }

    // MARK: - Moderation Actions

    func approveReports(for postId: String) async throws {
        try await updateReports(for: postId, status: .accepted)
        try await resetReportCount(for: postId)
    }

    func rejectReports(for postId: String) async throws {
        try await updateReports(for: postId, status: .rejected)
        try await resetReportCount(for: postId)
    }

    func dismissReports(for postId: String) async throws {
        try await updateReports(for: postId, status: .rejected)
        try await resetReportCount(for: postId)
    }

    func deleteReportedPost(postId: String) async throws {
        try await PostService.shared.deletePost(postId: postId)
        try await approveReports(for: postId)
    }

    // MARK: - Firestore Helpers

    private func fetchReports(targetId: String, targetType: ReportTargetType) async throws -> [ReportModel] {
        let snapshot = try await db.collection(FirestoreCollections.reports)
            .whereField("targetId", isEqualTo: targetId)
            .whereField("targetType", isEqualTo: targetType.rawValue)
            .getDocuments()

        return snapshot.documents.map { document in
            decode(id: document.documentID, data: document.data())
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    private func fetchPostReports() async throws -> [ReportModel] {
        let snapshot = try await db.collection(FirestoreCollections.reports)
            .whereField("targetType", isEqualTo: ReportTargetType.post.rawValue)
            .getDocuments()

        return snapshot.documents
            .map { document in
                decode(id: document.documentID, data: document.data())
            }
            .filter { $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
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

    private func resetReportCount(for postId: String) async throws {
        try await db.collection(FirestoreCollections.posts)
            .document(postId)
            .updateData(["reportCount": 0])
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
