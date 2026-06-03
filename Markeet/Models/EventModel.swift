import Foundation

struct EventModel: Identifiable, Equatable {
    let eventId: String
    var id: String { eventId }
    var title: String
    var description: String
    var imageURL: String?
    var location: String
    var startDate: Date
    var endDate: Date
    var capacity: Int
    var registrationDeadline: Date
    var mentorId: String
    var participantCount: Int
    var createdAt: Date
    var updatedAt: Date

    var isRegistrationOpen: Bool {
        Date() <= registrationDeadline && participantCount < capacity
    }
}

struct EventRegistrationModel: Identifiable, Equatable {
    let registrationId: String
    var id: String { registrationId }
    var eventId: String
    var userId: String
    var registeredAt: Date
}

struct EventParticipant: Identifiable, Equatable {
    var id: String { registration.registrationId }
    var registration: EventRegistrationModel
    var user: UserModel?
}
