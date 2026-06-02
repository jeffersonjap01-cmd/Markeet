import Foundation

@MainActor
final class GroupViewModel: ObservableObject {
    @Published var joinedGroups: [GroupModel] = []
    @Published var mentorGroups: [GroupModel] = []
    @Published var searchResults: [GroupModel] = []
    @Published var selectedTags: Set<String> = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

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

    func createCommunity(name: String, description: String, startDate: Date, endDate: Date, tag: String, status: CommunityStatus, session: SessionManager) async {
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
                status: status
            )
            await session.reloadCurrentUser()
            self.successMessage = "Community created."
            await self.load(session: session)
        }
    }

    func updateCommunity(_ group: GroupModel, name: String, description: String, startDate: Date, endDate: Date, tag: String, session: SessionManager) async {
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
                mentorId: user.uid
            )
            self.successMessage = "Community updated."
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
