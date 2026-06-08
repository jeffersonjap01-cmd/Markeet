//
//  ComunityView.swift
//  Marko
//
//  Created by student on 28/05/26.
//

import SwiftUI

/// Community tab for group discovery, membership, mentor management, and chat.
/// The active implementation is Firebase-backed through `GroupViewModel`.
struct ComunityView: View {
    // MARK: - Dependencies and State

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = GroupViewModel()
    @State private var showingSearch = false
    @State private var showingCreate = false

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

                Section {
                    Button {
                        showingSearch = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 42, height: 42)
                                .background(AppTheme.primary.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Search Community")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("Find open communities by marketing tag")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }
                }

                Section("Community Groups") {
                    if viewModel.joinedGroups.isEmpty && !viewModel.isLoading {
                        Text("Joined communities will appear here.")
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    ForEach(viewModel.joinedGroups) { group in
                        NavigationLink {
                            GroupChatView(group: group)
                                .environmentObject(session)
                        } label: {
                            communityListRow(group)
                        }
                    }
                }

            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if session.currentUser?.role == .mentor {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingCreate = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.joinedGroups.isEmpty {
                    ProgressView()
                }
            }
            .task {
                await viewModel.load(session: session)
            }
            .refreshable {
                await viewModel.load(session: session)
            }
            .sheet(isPresented: $showingSearch) {
                CommunitySearchView(viewModel: viewModel)
                    .environmentObject(session)
            }
            .sheet(isPresented: $showingCreate) {
                CommunityEditorView(title: "Create Community") { name, description, startDate, endDate, tag, status, rules, imageURL in
                    await viewModel.createCommunity(
                        name: name,
                        description: description,
                        startDate: startDate,
                        endDate: endDate,
                        tag: tag,
                        status: status,
                        rules: rules,
                        imageURL: imageURL,
                        session: session
                    )
                }
            }
        }
    }

    // MARK: - Community Rows

    private func communityListRow(_ group: GroupModel) -> some View {
        HStack(spacing: 12) {
            GroupAvatarView(group: group, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.groupName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(group.description.isEmpty ? group.tag : group.description)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            RoleBadge(role: group.status.displayName, color: group.status == .open ? AppTheme.success : AppTheme.textTertiary)
        }
        .padding(.vertical, 6)
    }

    private func initials(_ text: String) -> String {
        text
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }
}

private struct GroupAvatarView: View {
    let group: GroupModel
    let size: CGFloat

    var body: some View {
        AsyncImage(url: group.imageURL.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Circle()
                    .fill(AppTheme.primary)
                    .overlay {
                        Text(initials(group.groupName))
                            .font(.system(size: size * 0.3, weight: .bold))
                            .foregroundColor(.white)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func initials(_ text: String) -> String {
        text
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }
}

/// Tag-based search sheet.
/// Results are filtered by backend business rules so users only see communities
/// that are open, active, not full, and not already joined.
private struct CommunitySearchView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Select Tags") {
                    ForEach(AppConstants.marketingInterests, id: \.self) { tag in
                        Button {
                            viewModel.toggleTag(tag)
                        } label: {
                            HStack {
                                Text(tag)
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Image(systemName: viewModel.selectedTags.contains(tag) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.selectedTags.contains(tag) ? AppTheme.primary : AppTheme.textTertiary)
                            }
                        }
                    }
                }

                Section("Matching Communities") {
                    if viewModel.searchResults.isEmpty && !viewModel.isLoading {
                        Text("Select tags, then search.")
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    ForEach(viewModel.searchResults) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.groupName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(group.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                RoleBadge(role: group.tag, color: AppTheme.primary)
                            }

                            Text("\(group.members.count)/\(min(group.maxMembers, AppConstants.maxGroupMembers)) members")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textTertiary)

                            Button {
                                Task {
                                    await viewModel.join(group, session: session)
                                    dismiss()
                                }
                            } label: {
                                Label("Join", systemImage: "person.badge.plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Search Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Search") {
                        Task {
                            await viewModel.search(session: session)
                        }
                    }
                    .disabled(viewModel.selectedTags.isEmpty)
                }
            }
        }
    }
}

/// Shared form for creating and editing mentor communities.
/// The UI collects one tag; the service persists both `tag` and `[tag]`.
private struct CommunityEditorView: View {
    let title: String
    var group: GroupModel?
    let onSave: (String, String, Date, Date, String, CommunityStatus, String, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var tag: String
    @State private var status: CommunityStatus
    @State private var rules: String
    @State private var imageURL: String

    init(title: String, group: GroupModel? = nil, onSave: @escaping (String, String, Date, Date, String, CommunityStatus, String, String?) async -> Void) {
        self.title = title
        self.group = group
        self.onSave = onSave
        _name = State(initialValue: group?.groupName ?? "")
        _description = State(initialValue: group?.description ?? "")
        _startDate = State(initialValue: group?.startDate ?? Date())
        _endDate = State(initialValue: group?.endDate ?? Date().addingDays(30))
        _tag = State(initialValue: group?.tag ?? AppConstants.marketingInterests.first ?? "")
        _status = State(initialValue: group?.status ?? .open)
        _rules = State(initialValue: group?.rules ?? "")
        _imageURL = State(initialValue: group?.imageURL ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Community Name", text: $name)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...5)
                TextField("Group Rules", text: $rules, axis: .vertical)
                    .lineLimit(3...6)
                TextField("Group Image URL", text: $imageURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                Picker("Community Tag", selection: $tag) {
                    ForEach(AppConstants.marketingInterests, id: \.self) { tag in
                        Text(tag).tag(tag)
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(CommunityStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await onSave(
                                name.trimmingCharacters(in: .whitespacesAndNewlines),
                                description.trimmingCharacters(in: .whitespacesAndNewlines),
                                startDate,
                                endDate,
                                tag,
                                status,
                                rules.trimmingCharacters(in: .whitespacesAndNewlines),
                                imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || tag.isEmpty || endDate < startDate)
                }
            }
        }
    }
}

/// Realtime group chat backed by `chats/{groupId}/messages`.
struct GroupChatView: View {
    @State private var group: GroupModel
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingGroupInfo = false

    init(group: GroupModel) {
        _group = State(initialValue: group)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                showingGroupInfo = true
            } label: {
                GroupChatHeader(group: group)
            }
            .buttonStyle(.plain)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.messageId)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _, messages in
                    if let last = messages.last {
                        proxy.scrollTo(last.messageId, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 10) {
                TextField("Message", text: $viewModel.draftMessage, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task {
                        await viewModel.send(groupId: group.groupId, session: session)
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                .disabled(viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(AppTheme.surface)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingGroupInfo) {
            GroupInformationView(group: group) { updatedGroup in
                group = updatedGroup
            }
            .environmentObject(session)
        }
        .onAppear {
            viewModel.startListening(groupId: group.groupId)
        }
        .task {
            if let latestGroup = try? await GroupService.shared.fetchGroup(groupId: group.groupId) {
                group = latestGroup
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private func messageBubble(_ message: MessageModel) -> some View {
        let isMine = message.senderId == session.currentUser?.uid

        return HStack {
            if isMine {
                Spacer(minLength: 40)
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                if !isMine {
                    Text(message.senderName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isMine ? .white : AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(isMine ? AppTheme.primary : Color(hex: "E5E5EA"))
                    .cornerRadius(AppTheme.Radius.md)

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textTertiary)
            }

            if !isMine {
                Spacer(minLength: 40)
            }
        }
    }
}

private struct GroupChatHeader: View {
    let group: GroupModel

    var body: some View {
        HStack(spacing: 12) {
            GroupAvatarView(group: group, size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(group.groupName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct GroupInformationView: View {
    let initialGroup: GroupModel
    let onUpdate: (GroupModel) -> Void

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = GroupViewModel()
    @State private var group: GroupModel
    @State private var mentor: UserModel?
    @State private var members: [UserModel] = []
    @State private var memberSearchText = ""
    @State private var showingEdit = false
    @State private var isLoadingDetails = false
    @State private var groupInfoError: String?

    init(group: GroupModel, onUpdate: @escaping (GroupModel) -> Void) {
        self.initialGroup = group
        self.onUpdate = onUpdate
        _group = State(initialValue: group)
    }

    private var isMentorManager: Bool {
        guard let user = session.currentUser else { return false }
        return user.role == .mentor && group.mentors.contains(user.uid)
    }

    private var filteredMembers: [UserModel] {
        let query = memberSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return members }
        return members.filter {
            $0.fullName.lowercased().contains(query) || $0.email.lowercased().contains(query)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerSection
                    messageSection
                    informationSection
                    mentorSection
                    membersSection

                    if isMentorManager {
                        groupSettingsSection
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .padding(.bottom, 40)
            }

            if isLoadingDetails {
                LoadingOverlay(message: "Loading group information...")
            }
        }
        .navigationTitle("Group Information")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetails()
        }
        .refreshable {
            await loadDetails()
        }
        .sheet(isPresented: $showingEdit) {
            CommunityEditorView(title: "Edit Group", group: group) { name, description, startDate, endDate, tag, status, rules, imageURL in
                await viewModel.updateCommunity(
                    group,
                    name: name,
                    description: description,
                    startDate: startDate,
                    endDate: endDate,
                    tag: tag,
                    status: status,
                    rules: rules,
                    imageURL: imageURL,
                    session: session
                )
                await loadDetails()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            GroupAvatarView(group: group, size: 104)
                .shadow(color: AppTheme.primary.opacity(0.16), radius: 12, y: 5)

            VStack(spacing: 6) {
                Text(group.groupName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)

                RoleBadge(role: group.status.displayName, color: group.status == .open ? AppTheme.success : AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    @ViewBuilder
    private var messageSection: some View {
        if let successMessage = viewModel.successMessage {
            CommunityMessageCard(message: successMessage, color: AppTheme.success, icon: "checkmark.circle.fill")
        }

        if let errorMessage = viewModel.errorMessage ?? groupInfoError {
            CommunityMessageCard(message: errorMessage, color: AppTheme.error, icon: "exclamationmark.triangle.fill")
        }
    }

    private var informationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Group Details", actionTitle: nil)

            GroupInfoRow(label: "Description", value: group.description.isEmpty ? "No description provided." : group.description)
            GroupInfoRow(label: "Category", value: group.tag.isEmpty ? "Not available" : group.tag)
            GroupInfoRow(label: "Created", value: group.createdAt.formatted(date: .abbreviated, time: .omitted))
            GroupInfoRow(label: "Period", value: "\(group.startDate.formatted(date: .abbreviated, time: .omitted)) - \(group.endDate.formatted(date: .abbreviated, time: .omitted))")
            GroupInfoRow(label: "Rules", value: group.rules.isEmpty ? "No group rules have been added." : group.rules)
        }
        .cardStyle()
    }

    private var mentorSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Mentor Information", actionTitle: nil)

            if let mentor {
                HStack(spacing: AppTheme.Spacing.md) {
                    ProfileAvatarView(urlString: mentor.profileImageURL, size: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(mentor.fullName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(mentor.email)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()
                }
            } else {
                Text("Mentor information is not available.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .cardStyle()
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                SectionHeader(title: "Members", actionTitle: nil)
                Spacer()
                Text("\(members.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            }

            TextField("Search members", text: $memberSearchText)
                .textFieldStyle(.roundedBorder)

            if filteredMembers.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "No Members",
                    subtitle: memberSearchText.isEmpty ? "Members will appear here after users join this community." : "No members match your search."
                )
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(filteredMembers) { member in
                        MemberManagementRow(
                            member: member,
                            canRemove: isMentorManager
                        ) {
                            Task {
                                await viewModel.removeMember(member.uid, from: group, session: session)
                                await loadDetails()
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var groupSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Group Settings", actionTitle: nil)

            VStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    showingEdit = true
                } label: {
                    GroupSettingsRow(icon: "pencil", title: "Edit Group Information", color: AppTheme.primary)
                }

                Button {
                    showingEdit = true
                } label: {
                    GroupSettingsRow(icon: "doc.text", title: "Update Group Rules", color: AppTheme.info)
                }

                Button {
                    showingEdit = true
                } label: {
                    GroupSettingsRow(icon: "photo", title: "Change Group Image", color: AppTheme.success)
                }
            }
        }
        .cardStyle()
    }

    private func loadDetails() async {
        isLoadingDetails = true
        groupInfoError = nil
        defer { isLoadingDetails = false }

        do {
            let latestGroup = try await GroupService.shared.fetchGroup(groupId: group.groupId)
            group = latestGroup
            onUpdate(latestGroup)

            if let mentorId = latestGroup.mentors.first {
                mentor = try? await UserService.shared.fetchUser(uid: mentorId)
            }

            var loadedMembers: [UserModel] = []
            for memberId in latestGroup.members {
                if let user = try? await UserService.shared.fetchUser(uid: memberId) {
                    loadedMembers.append(user)
                }
            }
            members = loadedMembers.sorted { $0.fullName < $1.fullName }
        } catch {
            groupInfoError = error.localizedDescription
        }
    }
}

private struct GroupInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CommunityMessageCard: View {
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

private struct MemberManagementRow: View {
    let member: UserModel
    let canRemove: Bool
    let onRemove: () -> Void
    @State private var showingRemoveConfirmation = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ProfileAvatarView(urlString: member.profileImageURL, size: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(member.fullName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(member.email)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            if canRemove {
                Button {
                    showingRemoveConfirmation = true
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.error)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .confirmationDialog(
            "Remove this member from the group?",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Member", role: .destructive, action: onRemove)
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct GroupSettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

#Preview {
    ComunityView()
        .environmentObject(SessionManager())
}
