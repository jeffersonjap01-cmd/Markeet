import Foundation

/// View model for the admin Reports screen.
/// It loads real pending reports from Firestore and calls `ReportService` for
/// moderation actions such as approve, reject, delete, and dismiss.
@MainActor
final class AdminReportsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var reportedPosts: [AdminReportedPostModel] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    // MARK: - Report Loading and Moderation

    func loadReports() async {
        await run {
            self.reportedPosts = try await ReportService.shared.fetchReportedPosts()
        }
    }

    func approve(_ item: AdminReportedPostModel) async {
        await run {
            try await ReportService.shared.approveReports(for: item.post.postId)
            self.reportedPosts = try await ReportService.shared.fetchReportedPosts()
            self.successMessage = "Report resolved."
        }
    }

    func reject(_ item: AdminReportedPostModel) async {
        await run {
            try await ReportService.shared.rejectReports(for: item.post.postId)
            self.reportedPosts = try await ReportService.shared.fetchReportedPosts()
            self.successMessage = "Report rejected."
        }
    }

    func deletePost(_ item: AdminReportedPostModel) async {
        await run {
            try await ReportService.shared.deleteReportedPost(postId: item.post.postId)
            self.reportedPosts.removeAll { $0.post.postId == item.post.postId }
            self.successMessage = "Post removed."
        }
    }

    func dismiss(_ item: AdminReportedPostModel) async {
        await run {
            try await ReportService.shared.dismissReports(for: item.post.postId)
            self.reportedPosts.removeAll { $0.post.postId == item.post.postId }
            self.successMessage = "Report dismissed."
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
