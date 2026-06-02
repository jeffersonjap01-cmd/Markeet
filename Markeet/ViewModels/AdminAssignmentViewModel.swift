import Foundation

@MainActor
final class AdminAssignmentViewModel: ObservableObject {
    @Published var users: [UserModel] = []
    @Published var groups: [GroupModel] = []
    @Published var selectedUserId = ""
    @Published var selectedGroupIds: Set<String> = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    var defaultUsers: [UserModel] {
        users.filter { $0.role == .defaultUser && !$0.bannedStatus }
    }

    var selectedUser: UserModel? {
        users.first { $0.uid == selectedUserId }
    }

    var recommendableGroups: [GroupModel] {
        guard let selectedUser else { return groups }
        return groups.filter { GroupService.shared.canRecommendMember(user: selectedUser, group: $0) }
    }

    func load() async {
        await run {
            async let users = UserService.shared.fetchAllUsers()
            async let groups = GroupService.shared.fetchGroups()
            self.users = try await users
            self.groups = try await groups
            self.selectedUserId = self.defaultUsers.first?.uid ?? ""
        }
    }

    func toggleGroup(_ group: GroupModel) {
        if selectedGroupIds.contains(group.groupId) {
            selectedGroupIds.remove(group.groupId)
        } else {
            selectedGroupIds.insert(group.groupId)
        }
    }

    func sendRecommendations(session: SessionManager) async {
        await run {
            guard let adminId = session.currentUser?.uid else {
                throw AdminAssignmentError.missingAdmin
            }

            guard let selectedUser = self.selectedUser else {
                throw AdminAssignmentError.missingUser
            }

            let selectedGroups = self.groups.filter { self.selectedGroupIds.contains($0.groupId) }
            try await CommunityRecommendationService.shared.createRecommendations(
                user: selectedUser,
                groups: selectedGroups,
                adminId: adminId
            )

            self.selectedGroupIds.removeAll()
            self.successMessage = "Recommendations sent to \(selectedUser.fullName)."
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

enum AdminAssignmentError: LocalizedError {
    case missingAdmin
    case missingUser

    var errorDescription: String? {
        switch self {
        case .missingAdmin:
            "Admin session is missing."
        case .missingUser:
            "Select a user before sending recommendations."
        }
    }
}
