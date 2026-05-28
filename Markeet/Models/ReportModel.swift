import Foundation

enum ReportTargetType: String, Codable {
    case post
    case comment
    case chat
}

enum ReportStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

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
