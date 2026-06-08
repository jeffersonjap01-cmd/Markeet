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

                if session.currentUser?.role == .mentor {
                    Section("Mentor Communities") {
                        if viewModel.mentorGroups.isEmpty && !viewModel.isLoading {
                            Text("Communities you create will appear here.")
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        ForEach(viewModel.mentorGroups) { group in
                            NavigationLink {
                                MentorCommunityManageView(group: group, viewModel: viewModel)
                                    .environmentObject(session)
                            } label: {
                                communityListRow(group)
                            }
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
                CommunityEditorView(title: "Create Community") { name, description, startDate, endDate, tag, status in
                    await viewModel.createCommunity(
                        name: name,
                        description: description,
                        startDate: startDate,
                        endDate: endDate,
                        tag: tag,
                        status: status,
                        session: session
                    )
                }
            }
        }
    }

    // MARK: - Community Rows

    private func communityListRow(_ group: GroupModel) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.primary)
                .frame(width: 50, height: 50)
                .overlay {
                    Text(initials(group.groupName))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }

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
    let onSave: (String, String, Date, Date, String, CommunityStatus) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var tag: String
    @State private var status: CommunityStatus

    init(title: String, group: GroupModel? = nil, onSave: @escaping (String, String, Date, Date, String, CommunityStatus) async -> Void) {
        self.title = title
        self.group = group
        self.onSave = onSave
        _name = State(initialValue: group?.groupName ?? "")
        _description = State(initialValue: group?.description ?? "")
        _startDate = State(initialValue: group?.startDate ?? Date())
        _endDate = State(initialValue: group?.endDate ?? Date().addingDays(30))
        _tag = State(initialValue: group?.tag ?? AppConstants.marketingInterests.first ?? "")
        _status = State(initialValue: group?.status ?? .open)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Community Name", text: $name)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...5)
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
                                status
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

/// Mentor-only management screen for an owned community.
/// Mentors can edit metadata, open/close the community, and enter the group chat.
private struct MentorCommunityManageView: View {
    let group: GroupModel
    @ObservedObject var viewModel: GroupViewModel
    @EnvironmentObject private var session: SessionManager
    @State private var showingEdit = false

    private var currentGroup: GroupModel {
        viewModel.mentorGroups.first { $0.groupId == group.groupId } ?? group
    }

    var body: some View {
        List {
            Section("Community") {
                Text(currentGroup.description)
                LabeledContent("Tag", value: currentGroup.tag)
                LabeledContent("Members", value: "\(currentGroup.members.count)/\(min(currentGroup.maxMembers, AppConstants.maxGroupMembers))")
                LabeledContent("Mentors", value: "\(currentGroup.mentors.count)/\(min(currentGroup.maxMentors, AppConstants.maxGroupMentors))")
                LabeledContent("Period", value: "\(currentGroup.startDate.formatted(date: .abbreviated, time: .omitted)) - \(currentGroup.endDate.formatted(date: .abbreviated, time: .omitted))")
                LabeledContent("Status", value: currentGroup.status.displayName)
            }

            Section {
                NavigationLink {
                    GroupChatView(group: currentGroup)
                        .environmentObject(session)
                } label: {
                    Label("Open Chat", systemImage: "message.fill")
                }

                Button {
                    showingEdit = true
                } label: {
                    Label("Edit Community", systemImage: "pencil")
                }

                Button(currentGroup.status == .open ? "Close Community" : "Open Community") {
                    Task {
                        await viewModel.updateStatus(currentGroup, status: currentGroup.status == .open ? .closed : .open, session: session)
                    }
                }
            }
        }
        .navigationTitle(currentGroup.groupName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            CommunityEditorView(title: "Edit Community", group: currentGroup) { name, description, startDate, endDate, tag, status in
                await viewModel.updateCommunity(
                    currentGroup,
                    name: name,
                    description: description,
                    startDate: startDate,
                    endDate: endDate,
                    tag: tag,
                    status: status,
                    session: session
                )
            }
        }
    }
}

/// Realtime group chat backed by `chats/{groupId}/messages`.
struct GroupChatView: View {
    let group: GroupModel
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
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
        .navigationTitle(group.groupName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startListening(groupId: group.groupId)
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

#Preview {
    ComunityView()
        .environmentObject(SessionManager())
}
