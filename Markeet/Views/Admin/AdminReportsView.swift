import SwiftUI

struct AdminReportsView: View {
    @StateObject private var viewModel = AdminReportsViewModel()

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

            if viewModel.reportedPosts.isEmpty && !viewModel.isLoading {
                Text("No reported posts.")
                    .foregroundColor(AppTheme.textSecondary)
            }

            ForEach(viewModel.reportedPosts) { item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.author?.fullName ?? "Unknown Author")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(item.post.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textTertiary)
                        }

                        Spacer()

                        RoleBadge(role: item.reportStatus.rawValue.capitalized, color: statusColor(item.reportStatus))
                    }

                    Text(item.post.content)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)

                    Text("\(item.post.reportCount) report\(item.post.reportCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.warning)

                    HStack {
                        Button {
                            Task { await viewModel.approve(item) }
                        } label: {
                            Label("Approve", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await viewModel.reject(item) }
                        } label: {
                            Label("Reject", systemImage: "xmark.circle")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task { await viewModel.dismiss(item) }
                        } label: {
                            Label("Dismiss", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            Task { await viewModel.deletePost(item) }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading && viewModel.reportedPosts.isEmpty {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadReports()
        }
        .refreshable {
            await viewModel.loadReports()
        }
    }

    private func statusColor(_ status: ReportStatus) -> Color {
        switch status {
        case .pending:
            AppTheme.warning
        case .accepted:
            AppTheme.success
        case .rejected:
            AppTheme.textTertiary
        }
    }
}
