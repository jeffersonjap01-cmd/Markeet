import Foundation

enum CommunityRecommendationStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case accepted
    case rejected

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending:
            "Pending"
        case .accepted:
            "Accepted"
        case .rejected:
            "Rejected"
        }
    }
}

struct CommunityRecommendationModel: Identifiable, Equatable {
    let recommendationId: String
    var id: String { recommendationId }
    var userId: String
    var communityId: String
    var adminId: String
    var status: CommunityRecommendationStatus
    var createdAt: Date
    var respondedAt: Date?
}
