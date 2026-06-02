import Foundation

@MainActor
final class AdminUserManagementViewModel: ObservableObject {
    @Published var users: [UserModel] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

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
