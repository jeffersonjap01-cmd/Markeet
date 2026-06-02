import FirebaseFirestore
import Foundation

final class CommunityRecommendationService {
    static let shared = CommunityRecommendationService()

    private let db = Firestore.firestore()

    private init() {}

    func createRecommendations(user: UserModel, groups: [GroupModel], adminId: String) async throws {
        guard !groups.isEmpty else {
            throw CommunityRecommendationServiceError.noCommunitiesSelected
        }

        for group in groups {
            guard GroupService.shared.canRecommendMember(user: user, group: group) else {
                throw CommunityRecommendationServiceError.invalidRecommendationTarget
            }
        }

        let batch = db.batch()
        let now = Date()

        for group in groups {
            let recommendationId = UUID().uuidString
            let ref = recommendationDocument(recommendationId)

            batch.setData([
                "recommendationId": recommendationId,
                "userId": user.uid,
                "communityId": group.groupId,
                "adminId": adminId,
                "status": CommunityRecommendationStatus.pending.rawValue,
                "createdAt": Timestamp(date: now),
                "respondedAt": NSNull()
            ], forDocument: ref)
        }

        let notificationId = UUID().uuidString
        let notificationRef = db.collection(FirestoreCollections.notifications).document(notificationId)
        batch.setData([
            "notificationId": notificationId,
            "recipientId": user.uid,
            "title": "Community Recommendations",
            "body": "An admin recommended \(groups.count) communit\(groups.count == 1 ? "y" : "ies") for you.",
            "type": NotificationType.recommendation.rawValue,
            "read": false,
            "createdAt": Timestamp(date: now)
        ], forDocument: notificationRef)

        try await batch.commit()
    }

    func fetchPendingRecommendations(userId: String) async throws -> [CommunityRecommendationModel] {
        let snapshot = try await db.collection(FirestoreCollections.communityRecommendations)
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: CommunityRecommendationStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.map { document in
            decode(id: document.documentID, data: document.data())
        }
    }

    func rejectRecommendation(_ recommendation: CommunityRecommendationModel, userId: String) async throws {
        guard recommendation.userId == userId else {
            throw CommunityRecommendationServiceError.invalidRecommendationTarget
        }

        try await recommendationDocument(recommendation.recommendationId).updateData([
            "status": CommunityRecommendationStatus.rejected.rawValue,
            "respondedAt": Timestamp(date: Date())
        ])
    }

    private func recommendationDocument(_ recommendationId: String) -> DocumentReference {
        db.collection(FirestoreCollections.communityRecommendations).document(recommendationId)
    }

    private func decode(id: String, data: [String: Any]) -> CommunityRecommendationModel {
        CommunityRecommendationModel(
            recommendationId: data.string("recommendationId", default: id),
            userId: data.string("userId"),
            communityId: data.string("communityId"),
            adminId: data.string("adminId"),
            status: CommunityRecommendationStatus(rawValue: data.string("status")) ?? .pending,
            createdAt: data.date("createdAt"),
            respondedAt: data["respondedAt"].flatMap { value in
                (value as? Timestamp)?.dateValue()
            }
        )
    }
}

enum CommunityRecommendationServiceError: LocalizedError {
    case noCommunitiesSelected
    case invalidRecommendationTarget

    var errorDescription: String? {
        switch self {
        case .noCommunitiesSelected:
            "Select at least one community to recommend."
        case .invalidRecommendationTarget:
            "This recommendation is not valid for the selected user or community."
        }
    }
}
