import Foundation

@MainActor
final class CommunityRecommendationsViewModel: ObservableObject {
    @Published var recommendations: [CommunityRecommendationModel] = []
    @Published var groupsById: [String: GroupModel] = [:]
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    func load(userId: String) async {
        await run {
            async let recommendations = CommunityRecommendationService.shared.fetchPendingRecommendations(userId: userId)
            async let groups = GroupService.shared.fetchGroups()
            self.recommendations = try await recommendations
            let loadedGroups = try await groups
            self.groupsById = Dictionary(uniqueKeysWithValues: loadedGroups.map { ($0.groupId, $0) })
        }
    }

    func accept(_ recommendation: CommunityRecommendationModel, session: SessionManager) async {
        await run {
            guard let userId = session.currentUser?.uid else {
                throw CommunityRecommendationViewModelError.missingUser
            }

            try await GroupService.shared.acceptRecommendation(recommendation, userId: userId)
            await session.reloadCurrentUser()
            self.recommendations.removeAll { $0.recommendationId == recommendation.recommendationId }
            self.successMessage = "Community joined."
        }
    }

    func reject(_ recommendation: CommunityRecommendationModel, session: SessionManager) async {
        await run {
            guard let userId = session.currentUser?.uid else {
                throw CommunityRecommendationViewModelError.missingUser
            }

            try await CommunityRecommendationService.shared.rejectRecommendation(recommendation, userId: userId)
            self.recommendations.removeAll { $0.recommendationId == recommendation.recommendationId }
            self.successMessage = "Recommendation rejected."
        }
    }

    private func run(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum CommunityRecommendationViewModelError: LocalizedError {
    case missingUser

    var errorDescription: String? {
        switch self {
        case .missingUser:
            "User session is missing."
        }
    }
}
