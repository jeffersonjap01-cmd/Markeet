import FirebaseFirestore
import Foundation

final class GroupService {
    static let shared = GroupService()

    private let db = Firestore.firestore()

    private init() {}

    func createGroup(name: String, description: String, startDate: Date, endDate: Date, tag: String, mentorId: String, status: CommunityStatus) async throws {
        guard !tag.isEmpty else {
            throw GroupServiceError.missingTag
        }

        let groupId = UUID().uuidString
        let now = Date()
        let group = GroupModel(
            groupId: groupId,
            groupName: name,
            description: description,
            batchNumber: OnboardingManager.shared.currentBatch(at: now).batchNumber,
            startDate: startDate,
            endDate: endDate,
            registrationOpen: status == .open,
            status: status,
            tag: tag,
            members: [],
            mentors: [mentorId],
            maxMembers: AppConstants.maxGroupMembers,
            minMembers: AppConstants.minGroupMembers,
            maxMentors: AppConstants.maxGroupMentors,
            minMentors: AppConstants.minGroupMentors,
            createdAt: now
        )

        let batch = db.batch()
        batch.setData(encode(group), forDocument: groupDocument(groupId))
        batch.updateData([
            "assignedCommunities": FieldValue.arrayUnion([groupId])
        ], forDocument: db.collection(FirestoreCollections.users).document(mentorId))
        try await batch.commit()
    }

    func fetchGroups() async throws -> [GroupModel] {
        let snapshot = try await db.collection(FirestoreCollections.groups)
            .getDocuments()

        return snapshot.documents.map { document in
            normalize(decode(id: document.documentID, data: document.data()))
        }
        .sorted {
            if $0.createdAt == $1.createdAt {
                return $0.groupName < $1.groupName
            }
            return $0.createdAt > $1.createdAt
        }
    }

    func fetchGroup(groupId: String) async throws -> GroupModel {
        let snapshot = try await groupDocument(groupId).getDocument()
        guard let data = snapshot.data() else {
            throw GroupServiceError.groupNotFound
        }

        return normalize(decode(id: snapshot.documentID, data: data))
    }

    func searchGroups(tags: Set<String>, user: UserModel) async throws -> [GroupModel] {
        let groups = try await fetchGroups()
        return groups
            .filter { group in
                tags.contains(group.tag)
                    && canJoin(user: user, group: group)
            }
            .sorted { $0.groupName < $1.groupName }
    }

    func fetchJoinedGroups(user: UserModel) async throws -> [GroupModel] {
        let groups = try await fetchGroups()
        return groups
            .filter { group in
                group.members.contains(user.uid) || group.mentors.contains(user.uid)
            }
            .sorted { $0.groupName < $1.groupName }
    }

    func fetchMentorGroups(mentorId: String) async throws -> [GroupModel] {
        let groups = try await fetchGroups()
        return groups
            .filter { $0.mentors.contains(mentorId) }
            .sorted { $0.groupName < $1.groupName }
    }

    func recommendationScore(user: UserModel, group: GroupModel) -> Int {
        user.marketingInterests.contains(group.tag) ? 1 : 0
    }

    func canJoin(user: UserModel, group: GroupModel) -> Bool {
        guard group.isOpen,
              !group.members.contains(user.uid),
              !group.mentors.contains(user.uid),
              user.assignedCommunities.count < maxCommunities(for: user.role) else {
            return false
        }

        if user.role == .mentor {
            return group.mentors.count < min(group.maxMentors, AppConstants.maxGroupMentors)
        }

        return group.members.count < min(group.maxMembers, AppConstants.maxGroupMembers)
    }

    func joinGroup(groupId: String, userId: String) async throws {
        try await db.runVoidAsyncTransaction { transaction in
            let userRef = self.db.collection(FirestoreCollections.users).document(userId)
            let groupRef = self.groupDocument(groupId)

            let userSnapshot = try transaction.getDocument(userRef)
            let groupSnapshot = try transaction.getDocument(groupRef)

            guard let userData = userSnapshot.data(),
                  let groupData = groupSnapshot.data() else {
                throw GroupServiceError.groupNotFound
            }

            let role = self.decodeRole(userData.string("role"))
            let assignedCommunities = userData.stringArray("assignedCommunities")
            let members = groupData.stringArray("members")
            let mentors = groupData.stringArray("mentors")
            let status = self.decodeStatus(groupData.string("status"), registrationOpen: groupData.bool("registrationOpen"))
            let endDate = groupData.date("endDate")

            guard status == .open, groupData.bool("registrationOpen"), Date() <= endDate else {
                throw GroupServiceError.groupClosed
            }

            guard assignedCommunities.count < self.maxCommunities(for: role) else {
                throw role == .mentor ? GroupServiceError.mentorCommunityLimitReached : GroupServiceError.userCommunityLimitReached
            }

            guard !members.contains(userId), !mentors.contains(userId) else {
                throw GroupServiceError.alreadyInGroup
            }

            if role == .mentor {
                let maxMentors = min(groupData.int("maxMentors", default: AppConstants.maxGroupMentors), AppConstants.maxGroupMentors)
                guard mentors.count < maxMentors else {
                    throw GroupServiceError.groupMentorLimitReached
                }

                transaction.updateData([
                    "assignedCommunities": FieldValue.arrayUnion([groupId])
                ], forDocument: userRef)

                transaction.updateData([
                    "mentors": FieldValue.arrayUnion([userId])
                ], forDocument: groupRef)
            } else {
                let maxMembers = min(groupData.int("maxMembers", default: AppConstants.maxGroupMembers), AppConstants.maxGroupMembers)
                guard members.count < maxMembers else {
                    throw GroupServiceError.groupMemberLimitReached
                }

                transaction.updateData([
                    "assignedCommunities": FieldValue.arrayUnion([groupId]),
                    "role": UserRole.member.rawValue
                ], forDocument: userRef)

                transaction.updateData([
                    "members": FieldValue.arrayUnion([userId])
                ], forDocument: groupRef)
            }
        }
    }

    func updateGroup(groupId: String, name: String, description: String, startDate: Date, endDate: Date, tag: String, mentorId: String) async throws {
        let group = try await fetchGroup(groupId: groupId)
        guard group.mentors.contains(mentorId) else {
            throw GroupServiceError.notMentorOwner
        }

        guard group.members.count <= AppConstants.maxGroupMembers,
              group.mentors.count <= AppConstants.maxGroupMentors else {
            throw GroupServiceError.invalidCapacity
        }

        try await groupDocument(groupId).updateData([
            "groupName": name,
            "description": description,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "tag": tag,
            "tags": [tag]
        ])
    }

    func updateStatus(groupId: String, status: CommunityStatus, mentorId: String) async throws {
        let group = try await fetchGroup(groupId: groupId)
        guard group.mentors.contains(mentorId) else {
            throw GroupServiceError.notMentorOwner
        }

        guard group.members.count <= AppConstants.maxGroupMembers,
              group.mentors.count <= AppConstants.maxGroupMentors else {
            throw GroupServiceError.invalidCapacity
        }

        try await groupDocument(groupId).updateData([
            "status": status.rawValue,
            "registrationOpen": status == .open
        ])
    }

    private func maxCommunities(for role: UserRole) -> Int {
        role == .mentor ? AppConstants.maxMentorCommunities : AppConstants.maxJoinedCommunities
    }

    private func groupDocument(_ groupId: String) -> DocumentReference {
        db.collection(FirestoreCollections.groups).document(groupId)
    }

    private func encode(_ group: GroupModel) -> [String: Any] {
        [
            "groupId": group.groupId,
            "groupName": group.groupName,
            "description": group.description,
            "batchNumber": group.batchNumber,
            "startDate": Timestamp(date: group.startDate),
            "endDate": Timestamp(date: group.endDate),
            "registrationOpen": group.registrationOpen,
            "status": group.status.rawValue,
            "tag": group.tag,
            "tags": [group.tag],
            "members": group.members,
            "mentors": group.mentors,
            "maxMembers": group.maxMembers,
            "minMembers": group.minMembers,
            "maxMentors": group.maxMentors,
            "minMentors": group.minMentors,
            "createdAt": Timestamp(date: group.createdAt)
        ]
    }

    private func decode(id: String, data: [String: Any]) -> GroupModel {
        let tag = data.string("tag", default: data.stringArray("tags").first ?? "")
        let registrationOpen = data.bool("registrationOpen")
        let status = decodeStatus(data.string("status"), registrationOpen: registrationOpen)

        return GroupModel(
            groupId: data.string("groupId", default: id),
            groupName: data.string("groupName"),
            description: data.string("description"),
            batchNumber: data.int("batchNumber"),
            startDate: data.date("startDate"),
            endDate: data.date("endDate"),
            registrationOpen: registrationOpen,
            status: status,
            tag: tag,
            members: data.stringArray("members"),
            mentors: data.stringArray("mentors"),
            maxMembers: data.int("maxMembers", default: AppConstants.maxGroupMembers),
            minMembers: data.int("minMembers", default: AppConstants.minGroupMembers),
            maxMentors: data.int("maxMentors", default: AppConstants.maxGroupMentors),
            minMentors: data.int("minMentors", default: AppConstants.minGroupMentors),
            createdAt: data.date("createdAt", default: data.date("startDate"))
        )
    }

    private func normalize(_ group: GroupModel) -> GroupModel {
        guard group.status != .expired, Date() > group.endDate else {
            return group
        }

        var updatedGroup = group
        updatedGroup.status = .expired
        updatedGroup.registrationOpen = false
        return updatedGroup
    }

    private func decodeStatus(_ rawValue: String, registrationOpen: Bool) -> CommunityStatus {
        if let status = CommunityStatus(rawValue: rawValue) {
            return status
        }

        return registrationOpen ? .open : .closed
    }

    private func decodeRole(_ rawValue: String) -> UserRole {
        switch rawValue {
        case UserRole.member.rawValue:
            .member
        case UserRole.communityUser.rawValue:
            .communityUser
        case UserRole.mentor.rawValue:
            .mentor
        case UserRole.admin.rawValue:
            .admin
        default:
            .defaultUser
        }
    }
}

enum GroupServiceError: LocalizedError {
    case groupNotFound
    case groupClosed
    case userCommunityLimitReached
    case mentorCommunityLimitReached
    case groupMemberLimitReached
    case groupMentorLimitReached
    case alreadyInGroup
    case missingTag
    case notMentorOwner
    case invalidCapacity

    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            "Community was not found."
        case .groupClosed:
            "This community is closed or expired."
        case .userCommunityLimitReached:
            "This user already belongs to the maximum number of communities."
        case .mentorCommunityLimitReached:
            "This mentor already belongs to the maximum number of communities."
        case .groupMemberLimitReached:
            "This community has reached the maximum number of members."
        case .groupMentorLimitReached:
            "This community has reached the maximum number of mentors."
        case .alreadyInGroup:
            "This user already belongs to this community."
        case .missingTag:
            "Select one community tag."
        case .notMentorOwner:
            "Only a mentor in this community can manage it."
        case .invalidCapacity:
            "This community exceeds the allowed capacity."
        }
    }
}

private extension Firestore {
    func runVoidAsyncTransaction(_ updateBlock: @escaping (Transaction) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            runTransaction({ transaction, errorPointer in
                do {
                    try updateBlock(transaction)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
}
