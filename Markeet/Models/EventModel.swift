import Foundation

struct EventModel: Identifiable, Equatable {
    let eventId: String
    var id: String { eventId }
    var title: String
    var description: String
    var location: String
    var startDate: Date
    var endDate: Date
    var createdBy: String
    var attendees: [String]
}
