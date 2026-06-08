import Foundation

/// Type of content being reported for moderation.
/// The current admin report screen focuses on posts, while the enum keeps the
/// report model flexible for comments or chat messages later.
enum ReportTargetType: String, Codable {
    case post
    case comment
    case chat
}

/// Moderation status stored on each report document.
enum ReportStatus: String, Codable {
    case pending
    case underReview
    case accepted
    case rejected

    var displayName: String {
        switch self {
        case .pending:
            "Pending"
        case .underReview:
            "Under Review"
        case .accepted:
            "Resolved"
        case .rejected:
            "Rejected"
        }
    }
}

/// Firestore report submitted by a user.
/// For post reports, `targetId` points to `posts/{postId}` and pending reports
/// are grouped for the admin moderation queue.
struct ReportModel: Identifiable, Equatable {
    let reportId: String
    var id: String { reportId }
    var reporterId: String
    var targetId: String
    var targetType: ReportTargetType
    var reason: String
    var status: ReportStatus
    var createdAt: Date
}
