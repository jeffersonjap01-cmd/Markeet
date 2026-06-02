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

    func canRecommendMember(user: UserModel, group: GroupModel) -> Bool {
        user.role == .defaultUser
            && user.assignedCommunities.count < AppConstants.maxJoinedCommunities
            && !group.members.contains(user.uid)
            && !group.mentors.contains(user.uid)
            && group.members.count < min(group.maxMembers, AppConstants.maxGroupMembers)
            && group.registrationOpen
    }

    func canAssignMentor(user: UserModel, group: GroupModel) -> Bool {
        user.role == .mentor
            && user.assignedCommunities.count < AppConstants.maxMentorCommunities
            && !group.members.contains(user.uid)
            && !group.mentors.contains(user.uid)
            && group.mentors.count < min(group.maxMentors, AppConstants.maxGroupMentors)
            && group.registrationOpen
    }

    func acceptRecommendation(_ recommendation: CommunityRecommendationModel, userId: String) async throws {
        guard recommendation.userId == userId else {
            throw GroupServiceError.invalidRecommendation
        }

        try await db.runVoidAsyncTransaction { transaction in
            let userRef = self.db.collection(FirestoreCollections.users).document(userId)
            let groupRef = self.groupDocument(recommendation.communityId)
            let recommendationRef = self.recommendationDocument(recommendation.recommendationId)

            let userSnapshot = try transaction.getDocument(userRef)
            let groupSnapshot = try transaction.getDocument(groupRef)
            let recommendationSnapshot = try transaction.getDocument(recommendationRef)

            guard let userData = userSnapshot.data(),
                  let groupData = groupSnapshot.data(),
                  let recommendationData = recommendationSnapshot.data() else {
                throw GroupServiceError.groupNotFound
            }

            let status = CommunityRecommendationStatus(rawValue: recommendationData.string("status")) ?? .pending
            guard status == .pending else {
                throw GroupServiceError.recommendationAlreadyResolved
            }

            let assignedCommunities = userData.stringArray("assignedCommunities")
            let members = groupData.stringArray("members")
            let mentors = groupData.stringArray("mentors")
            let registrationOpen = groupData.bool("registrationOpen")
            let maxMembers = min(groupData.int("maxMembers", default: AppConstants.maxGroupMembers), AppConstants.maxGroupMembers)

            guard registrationOpen else {
                throw GroupServiceError.groupClosed
            }

            guard assignedCommunities.count < AppConstants.maxJoinedCommunities else {
                throw GroupServiceError.userCommunityLimitReached
            }

            guard members.count < maxMembers else {
                throw GroupServiceError.groupMemberLimitReached
            }

            guard !members.contains(userId), !mentors.contains(userId) else {
                throw GroupServiceError.alreadyInGroup
            }

            transaction.updateData([
                "assignedCommunities": FieldValue.arrayUnion([recommendation.communityId]),
                "role": UserRole.member.rawValue
            ], forDocument: userRef)

            transaction.updateData([
                "members": FieldValue.arrayUnion([userId])
            ], forDocument: groupRef)

            transaction.updateData([
                "status": CommunityRecommendationStatus.accepted.rawValue,
                "respondedAt": Timestamp(date: Date())
            ], forDocument: recommendationRef)

        }
    }

    private func groupDocument(_ groupId: String) -> DocumentReference {
        db.collection(FirestoreCollections.groups).document(groupId)
    }

    private func recommendationDocument(_ recommendationId: String) -> DocumentReference {
        db.collection(FirestoreCollections.communityRecommendations).document(recommendationId)
    }

    private func decode(id: String, data: [String: Any]) -> GroupModel {
        GroupModel(
            groupId: data.string("groupId", default: id),
            groupName: data.string("groupName"),
            batchNumber: data.int("batchNumber"),
            startDate: data.date("startDate"),
            endDate: data.date("endDate"),
            registrationOpen: data.bool("registrationOpen"),
            members: data.stringArray("members"),
            mentors: data.stringArray("mentors"),
            maxMembers: data.int("maxMembers", default: AppConstants.maxGroupMembers),
            minMembers: data.int("minMembers", default: AppConstants.minGroupMembers),
            maxMentors: data.int("maxMentors", default: AppConstants.maxGroupMentors),
            minMentors: data.int("minMentors", default: AppConstants.minGroupMentors)
        )
    }
}

enum GroupServiceError: LocalizedError {
    case groupNotFound
    case groupClosed
    case invalidRecommendation
    case recommendationAlreadyResolved
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
        case .invalidRecommendation:
            "This recommendation does not belong to the current user."
        case .recommendationAlreadyResolved:
            "This recommendation has already been accepted or rejected."
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
            }, completion: { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
}
