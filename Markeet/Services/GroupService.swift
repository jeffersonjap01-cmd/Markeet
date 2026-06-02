import FirebaseFirestore
import Foundation

final class GroupService {
    static let shared = GroupService()

    private let db = Firestore.firestore()

    private init() {}

    func fetchGroups() async throws -> [GroupModel] {
        let snapshot = try await db.collection(FirestoreCollections.groups)
            .order(by: "batchNumber", descending: true)
            .getDocuments()

        return snapshot.documents.map { document in
            decode(id: document.documentID, data: document.data())
        }
    }

    func fetchGroup(groupId: String) async throws -> GroupModel {
        let snapshot = try await groupDocument(groupId).getDocument()
        guard let data = snapshot.data() else {
            throw GroupServiceError.groupNotFound
        }

        return decode(id: snapshot.documentID, data: data)
    }

    func recommendationScore(user: UserModel, group: GroupModel) -> Int {
        let interests = Set(user.marketingInterests.map { $0.lowercased() })
        let tags = Set(group.tags.map { $0.lowercased() })
        return interests.intersection(tags).count
    }

    func canJoin(user: UserModel, group: GroupModel) -> Bool {
        guard group.registrationOpen,
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
            let registrationOpen = groupData.bool("registrationOpen")

            guard registrationOpen else {
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

    private func maxCommunities(for role: UserRole) -> Int {
        role == .mentor ? AppConstants.maxMentorCommunities : AppConstants.maxJoinedCommunities
    }

    private func groupDocument(_ groupId: String) -> DocumentReference {
        db.collection(FirestoreCollections.groups).document(groupId)
    }

    private func decode(id: String, data: [String: Any]) -> GroupModel {
        GroupModel(
            groupId: data.string("groupId", default: id),
            groupName: data.string("groupName"),
            batchNumber: data.int("batchNumber"),
            startDate: data.date("startDate"),
            endDate: data.date("endDate"),
            registrationOpen: data.bool("registrationOpen"),
            tags: data.stringArray("tags"),
            members: data.stringArray("members"),
            mentors: data.stringArray("mentors"),
            maxMembers: data.int("maxMembers", default: AppConstants.maxGroupMembers),
            minMembers: data.int("minMembers", default: AppConstants.minGroupMembers),
            maxMentors: data.int("maxMentors", default: AppConstants.maxGroupMentors),
            minMentors: data.int("minMentors", default: AppConstants.minGroupMentors)
        )
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

    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            "Community was not found."
        case .groupClosed:
            "This community is no longer active."
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
