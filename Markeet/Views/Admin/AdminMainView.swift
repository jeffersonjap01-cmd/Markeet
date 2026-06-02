import SwiftUI

struct AdminMainView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        TabView {
            Tab("Admin", systemImage: "shield.lefthalf.filled") {
                AdminDashboardView()
                    .environmentObject(session)
            }

            Tab("Users", systemImage: "person.2.badge.gearshape") {
                AdminUserManagementView()
                    .environmentObject(session)
            }

            Tab("Community", systemImage: "person.3.fill") {
                AdminPlaceholderView(
                    title: "Community Admin",
                    systemImage: "person.3.fill",
                    items: [
                        "Create and delete groups",
                        "Assign members and mentors",
                        "Moderate chats and remove messages"
                    ]
                )
            }

            Tab("Reports", systemImage: "exclamationmark.bubble.fill") {
                AdminPlaceholderView(
                    title: "Global Discussion",
                    systemImage: "exclamationmark.bubble.fill",
                    items: [
                        "Review reported posts",
                        "Approve or reject reports",
                        "Remove posts and issue warnings"
                    ]
                )
            }

            Tab("Profile", systemImage: "person.crop.circle.fill") {
                ProfileView()
                    .environmentObject(session)
            }
        }
        .tint(AppTheme.primary)
    }
}

struct AdminDashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    AdminSummaryCard(
                        title: "Home Management",
                        systemImage: "house.and.flag.fill",
                        items: [
                            "Manage learning materials",
                            "Add video materials",
                            "Manage marketing news and event news"
                        ]
                    )

                    AdminSummaryCard(
                        title: "Support and Accounts",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        items: [
                            "Manage help and support information",
                            "Remove or suspend accounts"
                        ]
                    )
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(Color(hex: "F2F2F7").ignoresSafeArea())
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AdminUserManagementView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AdminUserManagementViewModel()

    var body: some View {
        NavigationStack {
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

                ForEach(viewModel.users) { user in
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
            .navigationTitle("User Roles")
            .navigationBarTitleDisplayMode(.inline)
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

struct AdminPlaceholderView: View {
    let title: String
    let systemImage: String
    let items: [String]

    var body: some View {
        NavigationStack {
            ScrollView {
                AdminSummaryCard(title: title, systemImage: systemImage, items: items)
                    .padding(AppTheme.Spacing.lg)
            }
            .background(Color(hex: "F2F2F7").ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AdminSummaryCard: View {
    let title: String
    let systemImage: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.primary)
                    .cornerRadius(AppTheme.Radius.sm)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.success)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.lg)
        .shadow(color: AppTheme.Shadow.soft, radius: 8, y: 2)
    }
}

#Preview {
    AdminMainView()
        .environmentObject(SessionManager())
}
