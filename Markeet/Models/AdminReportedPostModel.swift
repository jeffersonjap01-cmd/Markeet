import Foundation

/// Aggregated view model used by the admin Reports screen.
/// It combines the reported post, optional author profile, and all reports for
/// that post so the UI can moderate from one object.
struct AdminReportedPostModel: Identifiable, Equatable {
    var id: String { post.postId }
    var post: PostModel
    var author: UserModel?
    var reports: [ReportModel]

    /// A single pending report keeps the whole item pending; otherwise the
    /// aggregate falls back to accepted/rejected for resolved admin lists.
    var reportStatus: ReportStatus {
        if reports.contains(where: { $0.status == .pending }) {
            return .pending
        }

        if reports.contains(where: { $0.status == .underReview }) {
            return .underReview
        }

        if reports.contains(where: { $0.status == .accepted }) {
            return .accepted
        }

        return .rejected
    }
}
