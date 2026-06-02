import Foundation

struct AdminReportedPostModel: Identifiable, Equatable {
    var id: String { post.postId }
    var post: PostModel
    var author: UserModel?
    var reports: [ReportModel]

    var reportStatus: ReportStatus {
        if reports.contains(where: { $0.status == .pending }) {
            return .pending
        }

        if reports.contains(where: { $0.status == .accepted }) {
            return .accepted
        }

        return .rejected
    }
}
