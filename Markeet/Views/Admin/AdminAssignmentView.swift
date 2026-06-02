import SwiftUI

struct AdminAssignmentView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AdminAssignmentViewModel()

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

            Section("Default Users") {
                if viewModel.defaultUsers.isEmpty {
                    Text("No default users available.")
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Picker("User", selection: selectedUserBinding) {
                        ForEach(viewModel.defaultUsers) { user in
                            Text(user.fullName).tag(user.uid)
                        }
                    }
                }
            }

            Section("Communities") {
                if viewModel.recommendableGroups.isEmpty {
                    Text("No recommendable communities available.")
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    ForEach(viewModel.recommendableGroups) { group in
                        Button {
                            viewModel.toggleGroup(group)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.groupName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Text("\(group.members.count)/\(min(group.maxMembers, AppConstants.maxGroupMembers)) members")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: viewModel.selectedGroupIds.contains(group.groupId) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.selectedGroupIds.contains(group.groupId) ? AppTheme.primary : AppTheme.textTertiary)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.sendRecommendations(session: session)
                    }
                } label: {
                    Label("Send Recommendations", systemImage: "paperplane.fill")
                }
                .disabled(viewModel.selectedUserId.isEmpty || viewModel.selectedGroupIds.isEmpty || viewModel.isLoading)
            }
        }
        .navigationTitle("Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var selectedUserBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedUserId },
            set: { userId in
                viewModel.selectedUserId = userId
                viewModel.selectedGroupIds.removeAll()
            }
        )
    }
}
