import SwiftUI

/// Modern admin report moderation dashboard.
/// The screen reads real report data through `AdminReportsViewModel` and keeps
/// all moderation actions connected to the existing Global Discussion backend.
struct AdminReportsView: View {
    // MARK: - State

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AdminReportsViewModel()
    @State private var selectedReport: AdminReportedPostModel?
    @State private var dashboardFilter: AdminReportFilter?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        messageSection
                        dashboardSection
                        filterSection
                        reportListSection
                    }
                    .padding(AppTheme.Spacing.lg)
                    .padding(.bottom, 90)
                }

                if viewModel.isLoading && viewModel.reportedPosts.isEmpty {
                    LoadingOverlay(message: "Loading reports...")
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search user, reason, or report ID")
            .task {
                await viewModel.loadReports()
            }
            .refreshable {
                await viewModel.loadReports()
            }
            .sheet(item: $selectedReport) { item in
                NavigationStack {
                    AdminReportDetailView(item: item, viewModel: viewModel)
                        .environmentObject(session)
                }
            }
            .sheet(item: $dashboardFilter) { filter in
                NavigationStack {
                    AdminFilteredReportsView(
                        viewModel: viewModel,
                        initialFilter: filter
                    )
                    .environmentObject(session)
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var messageSection: some View {
        if let successMessage = viewModel.successMessage {
            AdminReportMessageCard(message: successMessage, color: AppTheme.success, icon: "checkmark.circle.fill")
        }

        if let errorMessage = viewModel.errorMessage {
            AdminReportMessageCard(message: errorMessage, color: AppTheme.error, icon: "exclamationmark.triangle.fill")
        }
    }

    private var dashboardSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
            AdminReportStatCard(title: "Total Reports", value: viewModel.totalReports, icon: "doc.text.magnifyingglass", color: AppTheme.primary) {
                dashboardFilter = .all
            }
            AdminReportStatCard(title: "Pending", value: viewModel.pendingReports, icon: "clock.fill", color: AppTheme.warning) {
                dashboardFilter = .pending
            }
            AdminReportStatCard(title: "Resolved", value: viewModel.resolvedReports, icon: "checkmark.seal.fill", color: AppTheme.success) {
                dashboardFilter = .resolved
            }
            AdminReportStatCard(title: "Rejected", value: viewModel.rejectedReports, icon: "xmark.seal.fill", color: AppTheme.error) {
                dashboardFilter = .rejected
            }
        }
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(AdminReportFilter.allCases) { filter in
                    Button {
                        withAnimation(AppTheme.defaultAnimation) {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(viewModel.selectedFilter == filter ? .white : AppTheme.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(viewModel.selectedFilter == filter ? AppTheme.primary : AppTheme.primaryGlow)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var reportListSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Report Queue")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text("\(viewModel.filteredReportedPosts.count) item\(viewModel.filteredReportedPosts.count == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }

            if viewModel.filteredReportedPosts.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "checkmark.shield",
                    title: "No Reports Found",
                    subtitle: "Reports matching the current filters will appear here."
                )
                .padding(.top, AppTheme.Spacing.md)
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(viewModel.filteredReportedPosts) { item in
                        Button {
                            selectedReport = item
                        } label: {
                            AdminReportCard(item: item, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Report Cards

private struct AdminReportStatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 34, height: 34)
                        .background(color.opacity(0.12))
                        .clipShape(Circle())

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textTertiary)
                }

                Text("\(value)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
            .shadow(color: AppTheme.Shadow.soft, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct AdminFilteredReportsView: View {
    @EnvironmentObject private var session: SessionManager
    @ObservedObject var viewModel: AdminReportsViewModel
    let initialFilter: AdminReportFilter

    @State private var selectedReport: AdminReportedPostModel?
    @State private var selectedFilter: AdminReportFilter
    @State private var searchText = ""
    @State private var sort: AdminReportSort = .newest

    init(viewModel: AdminReportsViewModel, initialFilter: AdminReportFilter) {
        self.viewModel = viewModel
        self.initialFilter = initialFilter
        _selectedFilter = State(initialValue: initialFilter)
    }

    private var filteredItems: [AdminReportedPostModel] {
        viewModel.items(matching: selectedFilter, searchText: searchText, sort: sort)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    controls
                    reportList
                }
                .padding(AppTheme.Spacing.lg)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("\(initialFilter.rawValue) Reports")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search user, reason, or report ID")
        .sheet(item: $selectedReport) { item in
            NavigationStack {
                AdminReportDetailView(item: item, viewModel: viewModel)
                    .environmentObject(session)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AdminReportFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Sort")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                Picker("Sort", selection: $sort) {
                    ForEach(AdminReportSort.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.primary)
            }
        }
        .cardStyle()
    }

    private var reportList: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("\(filteredItems.count) report item\(filteredItems.count == 1 ? "" : "s")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()
            }

            if filteredItems.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No Reports",
                    subtitle: "Try a different filter, search term, or sorting option."
                )
            } else {
                ForEach(filteredItems) { item in
                    Button {
                        selectedReport = item
                    } label: {
                        AdminReportCard(item: item, viewModel: viewModel)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AdminReportCard: View {
    let item: AdminReportedPostModel
    @ObservedObject var viewModel: AdminReportsViewModel

    private var latestReport: ReportModel? {
        item.reports.sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(latestReport?.reason.isEmpty == false ? latestReport?.reason ?? "" : "Reported by user")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(2)

                    Text("Global Discussion Post")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                AdminReportStatusBadge(status: item.reportStatus)
            }

            Text(item.post.content)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(3)

            VStack(spacing: 8) {
                AdminReportInfoRow(label: "Reported user", value: item.author?.fullName ?? "Unknown Author")
                AdminReportInfoRow(label: "Reporter", value: latestReport.flatMap { viewModel.reporter(for: $0)?.fullName } ?? latestReport?.reporterId ?? "Unknown Reporter")
                AdminReportInfoRow(label: "Submitted", value: latestReport?.createdAt.formatted(date: .abbreviated, time: .shortened) ?? "-")
                AdminReportInfoRow(label: "Report ID", value: latestReport?.reportId ?? item.post.postId)
            }

            HStack {
                Label("\(item.reports.count) report\(item.reports.count == 1 ? "" : "s")", systemImage: "flag.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.warning)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        .shadow(color: AppTheme.Shadow.soft, radius: 8, y: 3)
    }
}

private struct AdminReportInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textTertiary)

            Spacer(minLength: AppTheme.Spacing.md)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct AdminReportStatusBadge: View {
    let status: ReportStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .pending:
            AppTheme.warning
        case .underReview:
            AppTheme.info
        case .accepted:
            AppTheme.success
        case .rejected:
            AppTheme.error
        }
    }
}

private struct AdminReportMessageCard: View {
    let message: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

// MARK: - Report Detail

private struct AdminReportDetailView: View {
    let item: AdminReportedPostModel
    @ObservedObject var viewModel: AdminReportsViewModel
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var confirmation: AdminReportAction?
    @State private var peopleExpanded = false
    @State private var historyExpanded = false
    @State private var showPostResolutionActions = false
    @State private var showBanConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                reportSummary
                contentPreview
                peopleSection
                reportsSection
                actionSection
            }
            .padding(AppTheme.Spacing.lg)
            .padding(.bottom, 60)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Report Detail")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            confirmation?.title ?? "Confirm Action",
            isPresented: Binding(
                get: { confirmation != nil },
                set: { if !$0 { confirmation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let confirmation {
                Button(confirmation.buttonTitle, role: confirmation.role) {
                    Task {
                        await perform(confirmation)
                    }
                }
            }

            Button("Cancel", role: .cancel) {
                confirmation = nil
            }
        } message: {
            Text(confirmation?.message ?? "")
        }
        .sheet(isPresented: $showPostResolutionActions) {
            AdminReportedUserActionSheet(
                item: item,
                viewModel: viewModel,
                onNoAction: {
                    showPostResolutionActions = false
                    dismiss()
                },
                onSuspend: { days in
                    Task {
                        await viewModel.suspendReportedUser(
                            item,
                            adminId: adminId,
                            days: days
                        )
                        showPostResolutionActions = false
                        dismiss()
                    }
                },
                onBan: {
                    showBanConfirmation = true
                }
            )
            .presentationDetents([.medium])
        }
        .confirmationDialog(
            "This action permanently disables the user's account.",
            isPresented: $showBanConfirmation,
            titleVisibility: .visible
        ) {
            Button("Ban User", role: .destructive) {
                Task {
                    await viewModel.banReportedUser(item, adminId: adminId)
                    showBanConfirmation = false
                    showPostResolutionActions = false
                    dismiss()
                }
            }

            Button("Cancel", role: .cancel) {
                showBanConfirmation = false
            }
        }
    }

    private var reportSummary: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Current Status")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                AdminReportStatusBadge(status: item.reportStatus)
            }

            Text("Global Discussion Post")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text("Submitted \(latestDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .cardStyle()
    }

    private var contentPreview: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Reported Content", actionTitle: nil)

            Text(item.post.content)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textPrimary)
                .lineSpacing(4)

            AdminReportInfoRow(label: "Post ID", value: item.post.postId)
            AdminReportInfoRow(label: "Created", value: item.post.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
        .cardStyle()
    }

    private var peopleSection: some View {
        AdminExpandableCard(
            title: "People Involved",
            isExpanded: $peopleExpanded
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                AdminReportPersonRow(title: "Reported User", user: item.author, fallback: item.post.authorId)

                if let author = item.author {
                    AdminReportInfoRow(label: "Reported user role", value: author.role.displayName)
                    AdminReportInfoRow(label: "Reported account status", value: accountStatus(for: author))
                    AdminReportInfoRow(label: "Reported contact", value: author.email.isEmpty ? "Not available" : author.email)
                }

                Divider()

                if let latestReport {
                    let reporter = viewModel.reporter(for: latestReport)
                    AdminReportPersonRow(
                        title: "Latest Reporter",
                        user: reporter,
                        fallback: latestReport.reporterId
                    )

                    if let reporter {
                        AdminReportInfoRow(label: "Reporter role", value: reporter.role.displayName)
                        AdminReportInfoRow(label: "Reporter account status", value: accountStatus(for: reporter))
                        AdminReportInfoRow(label: "Reporter contact", value: reporter.email.isEmpty ? "Not available" : reporter.email)
                    }
                }
            }
        }
    }

    private var reportsSection: some View {
        AdminExpandableCard(
            title: "Report History",
            isExpanded: $historyExpanded
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                AdminReportInfoRow(label: "Report created", value: latestDate.formatted(date: .abbreviated, time: .shortened))
                AdminReportInfoRow(label: "Current status", value: item.reportStatus.displayName)
                AdminReportInfoRow(label: "Admin actions", value: adminActionSummary)
                AdminReportInfoRow(label: "Resolution details", value: resolutionSummary)

                if let author = item.author {
                    AdminReportInfoRow(label: "Suspension/Ban history", value: moderationHistory(for: author))
                }

                Divider()

                ForEach(item.reports.sorted { $0.createdAt > $1.createdAt }) { report in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(report.reason.isEmpty ? "Reported by user" : report.reason)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            AdminReportStatusBadge(status: report.status)
                        }

                        AdminReportInfoRow(label: "Report ID", value: report.reportId)
                        AdminReportInfoRow(label: "Reporter", value: viewModel.reporter(for: report)?.fullName ?? report.reporterId)
                        AdminReportInfoRow(label: "Submitted", value: report.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                }
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                confirmation = .underReview
            } label: {
                Label("Mark as Under Review", systemImage: "eye.fill")
                    .secondaryButton()
            }

            Button {
                confirmation = .resolve
            } label: {
                Label("Resolve Report", systemImage: "checkmark.circle.fill")
                    .primaryButton()
            }

            Button {
                confirmation = .reject
            } label: {
                Label("Reject Report", systemImage: "xmark.circle.fill")
                    .secondaryButton()
            }
        }
        .cardStyle()
    }

    private var latestReport: ReportModel? {
        item.reports.sorted { $0.createdAt > $1.createdAt }.first
    }

    private var latestDate: Date {
        item.reports.map(\.createdAt).max() ?? item.post.createdAt
    }

    private var adminId: String {
        session.currentUser?.uid ?? ""
    }

    private var adminActionSummary: String {
        switch item.reportStatus {
        case .pending:
            "No admin action has been completed yet."
        case .underReview:
            "An admin marked this report as under review."
        case .accepted:
            "An admin resolved this report and removed the reported content."
        case .rejected:
            "An admin rejected this report and kept the content unchanged."
        }
    }

    private var resolutionSummary: String {
        switch item.reportStatus {
        case .accepted:
            "Reported content is removed from the application."
        case .rejected:
            "Report is closed without changing the reported content."
        case .pending, .underReview:
            "No resolution has been applied yet."
        }
    }

    private func perform(_ action: AdminReportAction) async {
        switch action {
        case .underReview:
            await viewModel.markUnderReview(item)
        case .resolve:
            await viewModel.resolveAndDelete(item, adminId: adminId)
        case .reject:
            await viewModel.reject(item, adminId: adminId)
        }

        confirmation = nil
        if action == .resolve {
            showPostResolutionActions = viewModel.errorMessage == nil
        } else {
            dismiss()
        }
    }

    private func accountStatus(for user: UserModel) -> String {
        if user.isBanned || user.bannedStatus {
            return "Banned"
        }

        if user.isSuspended {
            return "Suspended until \(user.suspensionEndDate?.formatted(date: .abbreviated, time: .shortened) ?? "unknown date")"
        }

        return "Active"
    }

    private func moderationHistory(for user: UserModel) -> String {
        if user.isBanned || user.bannedStatus {
            return "Banned on \(user.banDate?.formatted(date: .abbreviated, time: .shortened) ?? "unknown date"). \(user.banReason ?? "")"
        }

        if user.isSuspended {
            return "Suspended until \(user.suspensionEndDate?.formatted(date: .abbreviated, time: .shortened) ?? "unknown date"). \(user.suspensionReason ?? "")"
        }

        return "No suspension or ban recorded."
    }
}

private struct AdminExpandableCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Button {
                withAnimation(AppTheme.defaultAnimation) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
    }
}

private struct AdminReportedUserActionSheet: View {
    let item: AdminReportedPostModel
    @ObservedObject var viewModel: AdminReportsViewModel
    let onNoAction: () -> Void
    let onSuspend: (Int) -> Void
    let onBan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Content has been removed successfully.")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("What action would you like to take against the reported user?")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Button {
                onNoAction()
            } label: {
                Label("No Action", systemImage: "checkmark.circle")
                    .secondaryButton()
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Temporary Suspend")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach([1, 3, 7, 30], id: \.self) { days in
                        Button("\(days) Day\(days == 1 ? "" : "s")") {
                            onSuspend(days)
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppTheme.primaryGlow)
                        .clipShape(Capsule())
                    }
                }
            }

            Button {
                onBan()
            } label: {
                Label("Permanent Ban", systemImage: "hand.raised.fill")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppTheme.error)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
            }
            .buttonStyle(.plain)

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Applying moderation action...")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

private struct AdminReportPersonRow: View {
    let title: String
    let user: UserModel?
    let fallback: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ProfileAvatarView(urlString: user?.profileImageURL, size: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)

                Text(user?.fullName ?? fallback)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                if let email = user?.email, !email.isEmpty {
                    Text(email)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
    }
}

private enum AdminReportAction {
    case underReview
    case resolve
    case reject

    var title: String {
        switch self {
        case .underReview:
            "Mark as Under Review?"
        case .resolve:
            "Are you sure you want to resolve this report?"
        case .reject:
            "Reject this report?"
        }
    }

    var message: String {
        switch self {
        case .underReview:
            "This report will remain visible and be marked as actively reviewed."
        case .resolve:
            "The reported content will be removed from the application."
        case .reject:
            "The report will be closed as rejected. The reported content and user account will not be changed."
        }
    }

    var buttonTitle: String {
        switch self {
        case .underReview:
            "Mark Under Review"
        case .resolve:
            "Continue"
        case .reject:
            "Reject"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .reject:
            .destructive
        case .underReview, .resolve:
            nil
        }
    }
}
