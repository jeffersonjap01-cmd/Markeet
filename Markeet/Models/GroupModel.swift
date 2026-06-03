import Foundation

/// Lifecycle state for a mentor-created community.
/// Closed and expired communities are intentionally hidden from search/join flows.
enum CommunityStatus: String, Codable, CaseIterable, Identifiable {
    case open
    case closed
    case expired

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .open:
            "Open"
        case .closed:
            "Closed"
        case .expired:
            "Expired"
        }
    }
}

/// Represents a community/group that users can join and mentors can manage.
/// Membership is stored as arrays of user ids so Firestore can update joins with
/// `arrayUnion` while keeping the user profile and group document in sync.
struct GroupModel: Identifiable, Equatable {
    let groupId: String
    var id: String { groupId }
    var groupName: String
    var description: String
    var batchNumber: Int
    var startDate: Date
    var endDate: Date
    var registrationOpen: Bool
    var status: CommunityStatus
    var tag: String
    var members: [String]
    var mentors: [String]
    var maxMembers: Int
    var minMembers: Int
    var maxMentors: Int
    var minMentors: Int
    var createdAt: Date

    var isActive: Bool {
        Date() <= endDate
    }

    /// Search and join flows use this computed value to enforce the current rules:
    /// open status, registration enabled, and active date range.
    var isOpen: Bool {
        status == .open && registrationOpen && isActive
    }

    var tags: [String] {
        tag.isEmpty ? [] : [tag]
    }
}
