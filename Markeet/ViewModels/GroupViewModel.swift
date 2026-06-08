import Foundation

/// State and business logic for the Community tab.
/// It loads joined communities, mentor-owned communities, tag search results,
/// and delegates all Firestore writes to `GroupService`.
@MainActor
final class GroupViewModel: ObservableObject {
    // MARK: - Published State

    @Published var joinedGroups: [GroupModel] = []
    @Published var mentorGroups: [GroupModel] = []
    @Published var searchResults: [GroupModel] = []
    @Published var selectedTags: Set<String> = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    // MARK: - Loading

    func load(session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw GroupViewModelError.missingUser
            }

            self.joinedGroups = try await GroupService.shared.fetchJoinedGroups(user: user)

            if user.role == .mentor {
                self.mentorGroups = try await GroupService.shared.fetchMentorGroups(mentorId: user.uid)
            } else {
                self.mentorGroups = []
            }
        }
    }

    // MARK: - Search

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func search(session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw GroupViewModelError.missingUser
            }

            self.searchResults = try await GroupService.shared.searchGroups(tags: self.selectedTags, user: user)
        }
    }

    // MARK: - Membership

    func join(_ group: GroupModel, session: SessionManager) async {
        await run {
            guard let userId = session.currentUser?.uid else {
                throw GroupViewModelError.missingUser
            }

            try await GroupService.shared.joinGroup(groupId: group.groupId, userId: userId)
            await session.reloadCurrentUser()
            self.successMessage = "Joined \(group.groupName)."
            await self.load(session: session)
            await self.search(session: session)
        }
    }

    // MARK: - Mentor Management

    func createCommunity(name: String, description: String, startDate: Date, endDate: Date, tag: String, status: CommunityStatus, rules: String = "", imageURL: String? = nil, session: SessionManager) async {
        await run {
            guard let user = session.currentUser, user.role == .mentor else {
                throw GroupViewModelError.mentorRequired
            }

            try await GroupService.shared.createGroup(
                name: name,
                description: description,
                startDate: startDate,
                endDate: endDate,
                tag: tag,
                mentorId: user.uid,
                status: status,
                rules: rules,
                imageURL: imageURL
            )
            await session.reloadCurrentUser()
            self.successMessage = "Community created."
            await self.load(session: session)
        }
    }

    func updateCommunity(_ group: GroupModel, name: String, description: String, startDate: Date, endDate: Date, tag: String, status: CommunityStatus, rules: String = "", imageURL: String? = nil, session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw GroupViewModelError.missingUser
            }

            try await GroupService.shared.updateGroup(
                groupId: group.groupId,
                name: name,
                description: description,
                startDate: startDate,
                endDate: endDate,
                tag: tag,
                status: status,
                mentorId: user.uid,
                rules: rules,
                imageURL: imageURL
            )
            self.successMessage = "Community updated."
            await self.load(session: session)
        }
    }

    func updateGroupInfo(_ group: GroupModel, name: String, description: String, rules: String, imageURL: String?, session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw GroupViewModelError.missingUser
            }

            try await GroupService.shared.updateGroupInfo(
                groupId: group.groupId,
                name: name,
                description: description,
                rules: rules,
                imageURL: imageURL,
                mentorId: user.uid
            )
            self.successMessage = "Group information updated."
            await self.load(session: session)
        }
    }

    func updateStatus(_ group: GroupModel, status: CommunityStatus, session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw GroupViewModelError.missingUser
            }

            try await GroupService.shared.updateStatus(groupId: group.groupId, status: status, mentorId: user.uid)
            self.successMessage = "Community is now \(status.displayName)."
            await self.load(session: session)
        }
    }

    func removeMember(_ memberId: String, from group: GroupModel, session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw GroupViewModelError.missingUser
            }

            try await GroupService.shared.removeMember(groupId: group.groupId, memberId: memberId, mentorId: user.uid)
            self.successMessage = "Member removed."
            await self.load(session: session)
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

enum GroupViewModelError: LocalizedError {
    case missingUser
    case mentorRequired

    var errorDescription: String? {
        switch self {
        case .missingUser:
            "User session is missing."
        case .mentorRequired:
            "Only mentors can create communities."
        }
    }
}
