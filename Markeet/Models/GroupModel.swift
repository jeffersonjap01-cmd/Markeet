import Foundation

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

    var isOpen: Bool {
        status == .open && registrationOpen && isActive
    }

    var tags: [String] {
        tag.isEmpty ? [] : [tag]
    }
}
