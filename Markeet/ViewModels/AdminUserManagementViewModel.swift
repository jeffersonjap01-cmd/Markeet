import Foundation

/// Admin view model for searching registered users and changing roles.
/// Role updates are written through `UserService` and the current session is
/// refreshed if the admin edits their own account.
@MainActor
final class AdminUserManagementViewModel: ObservableObject {
    // MARK: - Published State

    @Published var users: [UserModel] = []
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    // MARK: - Filtering

    var filteredUsers: [UserModel] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return users }

        return users.filter { user in
            user.fullName.lowercased().contains(query)
                || user.email.lowercased().contains(query)
                || user.role.displayName.lowercased().contains(query)
        }
    }

    // MARK: - User Loading and Role Updates

    func loadUsers() async {
        await run {
            self.users = try await UserService.shared.fetchAllUsers()
        }
    }

    func updateRole(for user: UserModel, to role: UserRole, session: SessionManager) async {
        await run {
            try await UserService.shared.updateRole(uid: user.uid, role: role)

            if let index = self.users.firstIndex(where: { $0.uid == user.uid }) {
                self.users[index].role = role
            }

            if session.currentUser?.uid == user.uid {
                await session.reloadCurrentUser()
            }

            self.successMessage = "\(user.fullName)'s role was updated to \(role.displayName)."
        }
    }

    // MARK: - Shared Async Wrapper

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
