import Foundation

enum AdminReportFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"
    case underReview = "Under Review"
    case resolved = "Resolved"
    case rejected = "Rejected"

    var id: String { rawValue }
}

enum AdminReportSort: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case mostReported = "Most Reported"

    var id: String { rawValue }
}

/// View model for the admin Reports screen.
/// It loads real pending reports from Firestore and calls `ReportService` for
/// moderation actions such as approve, reject, delete, and dismiss.
@MainActor
final class AdminReportsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var reportedPosts: [AdminReportedPostModel] = []
    @Published var reportersById: [String: UserModel] = [:]
    @Published var searchText = ""
    @Published var selectedFilter: AdminReportFilter = .all
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    var totalReports: Int {
        reportedPosts.flatMap(\.reports).count
    }

    var pendingReports: Int {
        countReports(with: .pending)
    }

    var underReviewReports: Int {
        countReports(with: .underReview)
    }

    var resolvedReports: Int {
        countReports(with: .accepted)
    }

    var rejectedReports: Int {
        countReports(with: .rejected)
    }

    var filteredReportedPosts: [AdminReportedPostModel] {
        reportedPosts.filter { item in
            matchesSelectedFilter(item) && matchesSearch(item)
        }
    }

    // MARK: - Report Loading and Moderation

    func loadReports() async {
        await run {
            let posts = try await ReportService.shared.fetchReportedPosts()
            self.reportedPosts = posts
            self.reportersById = try await self.loadReporters(for: posts)
        }
    }

    func markUnderReview(_ item: AdminReportedPostModel) async {
        await run {
            try await ReportService.shared.markReportsUnderReview(for: item.post.postId)
            try await self.reloadReportData()
            self.successMessage = "Report marked as under review."
        }
    }

    func resolveAndDelete(_ item: AdminReportedPostModel, adminId: String) async {
        await run {
            try await ReportService.shared.resolveReport(item, adminId: adminId)
            try await self.reloadReportData()
            self.successMessage = "Content removed and report resolved."
        }
    }

    func reject(_ item: AdminReportedPostModel, adminId: String) async {
        await run {
            try await ReportService.shared.rejectReport(item, adminId: adminId)
            try await self.reloadReportData()
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
            self.reportersById = try await self.loadReporters(for: self.reportedPosts)
            self.successMessage = "Report dismissed."
        }
    }

    func suspendReportedUser(_ item: AdminReportedPostModel, adminId: String, days: Int) async {
        await run {
            try await ReportService.shared.suspendReportedUser(
                item,
                adminId: adminId,
                days: days,
                reason: "Action taken after resolved report."
            )
            try await self.reloadReportData()
            self.successMessage = "User suspended for \(days) day\(days == 1 ? "" : "s")."
        }
    }

    func banReportedUser(_ item: AdminReportedPostModel, adminId: String) async {
        await run {
            try await ReportService.shared.banReportedUser(
                item,
                adminId: adminId,
                reason: "Permanent ban after resolved report."
            )
            try await self.reloadReportData()
            self.successMessage = "User permanently banned."
        }
    }

    func items(matching filter: AdminReportFilter, searchText: String, sort: AdminReportSort) -> [AdminReportedPostModel] {
        filteredItems(from: reportedPosts, filter: filter, searchText: searchText, sort: sort)
    }

    func reporter(for report: ReportModel) -> UserModel? {
        reportersById[report.reporterId]
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

    private func loadReporters(for posts: [AdminReportedPostModel]) async throws -> [String: UserModel] {
        var output: [String: UserModel] = [:]
        let reporterIds = Set(posts.flatMap { $0.reports.map(\.reporterId) })

        for reporterId in reporterIds {
            if let user = try? await UserService.shared.fetchUser(uid: reporterId) {
                output[reporterId] = user
            }
        }

        return output
    }

    private func reloadReportData() async throws {
        reportedPosts = try await ReportService.shared.fetchReportedPosts()
        reportersById = try await loadReporters(for: reportedPosts)
    }

    private func countReports(with status: ReportStatus) -> Int {
        reportedPosts.flatMap(\.reports).filter { $0.status == status }.count
    }

    private func matchesSelectedFilter(_ item: AdminReportedPostModel) -> Bool {
        matchesFilter(item, filter: selectedFilter)
    }

    private func matchesFilter(_ item: AdminReportedPostModel, filter: AdminReportFilter) -> Bool {
        switch filter {
        case .all:
            true
        case .pending:
            item.reportStatus == .pending
        case .underReview:
            item.reportStatus == .underReview
        case .resolved:
            item.reportStatus == .accepted
        case .rejected:
            item.reportStatus == .rejected
        }
    }

    private func matchesSearch(_ item: AdminReportedPostModel) -> Bool {
        matchesSearch(item, query: searchText)
    }

    private func filteredItems(
        from items: [AdminReportedPostModel],
        filter: AdminReportFilter,
        searchText: String,
        sort: AdminReportSort
    ) -> [AdminReportedPostModel] {
        let filtered = items.filter { item in
            matchesFilter(item, filter: filter) && matchesSearch(item, query: searchText)
        }

        switch sort {
        case .newest:
            return filtered.sorted { latestDate(for: $0) > latestDate(for: $1) }
        case .oldest:
            return filtered.sorted { latestDate(for: $0) < latestDate(for: $1) }
        case .mostReported:
            return filtered.sorted { $0.reports.count > $1.reports.count }
        }
    }

    private func matchesSearch(_ item: AdminReportedPostModel, query rawQuery: String) -> Bool {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return true }

        let authorName = item.author?.fullName.lowercased() ?? ""
        let postId = item.post.postId.lowercased()
        let postContent = item.post.content.lowercased()
        let reportText = item.reports.map { report in
            let reporterName = reportersById[report.reporterId]?.fullName.lowercased() ?? ""
            return [
                report.reportId.lowercased(),
                report.reason.lowercased(),
                report.reporterId.lowercased(),
                reporterName
            ].joined(separator: " ")
        }.joined(separator: " ")

        return authorName.contains(query)
            || postId.contains(query)
            || postContent.contains(query)
            || reportText.contains(query)
    }

    private func latestDate(for item: AdminReportedPostModel) -> Date {
        item.reports.map(\.createdAt).max() ?? item.post.createdAt
    }
}
