import Foundation

struct GroupModel: Identifiable, Equatable {
    let groupId: String
    var id: String { groupId }
    var groupName: String
    var batchNumber: Int
    var startDate: Date
    var endDate: Date
    var registrationOpen: Bool
    var members: [String]
    var mentors: [String]
    var maxMembers: Int
    var minMembers: Int
    var maxMentors: Int
    var minMentors: Int
}
