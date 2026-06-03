import SwiftUI

struct AdminUserManagementView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AdminUserManagementViewModel()

    var body: some View {
        List {
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.success)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.error)
            }

            if viewModel.filteredUsers.isEmpty && !viewModel.isLoading {
                Text("No users found.")
                    .foregroundColor(AppTheme.textSecondary)
            }

            ForEach(viewModel.filteredUsers) { user in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        ProfileAvatarView(urlString: user.profileImageURL, size: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(user.fullName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(user.email)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        RoleBadge(role: user.role.displayName, color: AppTheme.roleColor(user.role))
                    }

                    Picker("Role", selection: binding(for: user)) {
                        ForEach(UserRole.adminAssignableRoles) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(viewModel.isLoading || user.uid == session.currentUser?.uid)

                    if user.uid == session.currentUser?.uid {
                        Text("You cannot change your own admin role here.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("User Management")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search users")
        .overlay {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadUsers()
        }
        .refreshable {
            await viewModel.loadUsers()
        }
    }

    private func binding(for user: UserModel) -> Binding<UserRole> {
        Binding(
            get: {
                viewModel.users.first(where: { $0.uid == user.uid })?.role ?? user.role
            },
            set: { newRole in
                Task {
                    await viewModel.updateRole(for: user, to: newRole, session: session)
                }
            }
        )
    }
}
