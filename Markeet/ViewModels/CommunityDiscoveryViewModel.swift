import Foundation

struct CommunityDiscoveryItem: Identifiable, Equatable {
    var id: String { group.groupId }
    let group: GroupModel
    let score: Int
    let canJoin: Bool
    let alreadyJoined: Bool
}

@MainActor
final class CommunityDiscoveryViewModel: ObservableObject {
    @Published var recommendations: [CommunityDiscoveryItem] = []
    @Published var allCommunities: [CommunityDiscoveryItem] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    func load(session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw CommunityDiscoveryError.missingUser
            }

            let groups = try await GroupService.shared.fetchGroups()
            self.apply(groups: groups, user: user)
        }
    }

    func join(_ item: CommunityDiscoveryItem, session: SessionManager) async {
        await run {
            guard let userId = session.currentUser?.uid else {
                throw CommunityDiscoveryError.missingUser
            }

            guard item.canJoin else {
                throw CommunityDiscoveryError.cannotJoin
            }

            try await GroupService.shared.joinGroup(groupId: item.group.groupId, userId: userId)
            await session.reloadCurrentUser()
            self.successMessage = "Joined \(item.group.groupName)."
            if let user = session.currentUser {
                let groups = try await GroupService.shared.fetchGroups()
                self.apply(groups: groups, user: user)
            }
        }
    }

    private func apply(groups: [GroupModel], user: UserModel) {
        let items = groups.map { group in
            CommunityDiscoveryItem(
                group: group,
                score: GroupService.shared.recommendationScore(user: user, group: group),
                canJoin: GroupService.shared.canJoin(user: user, group: group),
                alreadyJoined: group.members.contains(user.uid) || group.mentors.contains(user.uid)
            )
        }

        recommendations = items
            .filter { $0.score > 0 && $0.canJoin }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.group.groupName < rhs.group.groupName
                }
                return lhs.score > rhs.score
            }

        allCommunities = items.sorted { $0.group.groupName < $1.group.groupName }
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

enum CommunityDiscoveryError: LocalizedError {
    case missingUser
    case cannotJoin

    var errorDescription: String? {
        switch self {
        case .missingUser:
            "User session is missing."
        case .cannotJoin:
            "This community cannot accept this user right now."
        }
    }
}
