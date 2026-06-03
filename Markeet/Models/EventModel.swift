import Foundation

/// Mentor-created event stored in `events`.
/// Members register through separate `event_registrations` documents so the app
/// can track participant count and registration history independently.
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

    /// Registration is available only before the deadline and while capacity remains.
    var isRegistrationOpen: Bool {
        Date() <= registrationDeadline && participantCount < capacity
    }
}

/// Member registration document for a mentor-created event.
/// The document id is generated as `eventId_userId` to prevent duplicate tickets.
struct EventRegistrationModel: Identifiable, Equatable {
    let registrationId: String
    var id: String { registrationId }
    var eventId: String
    var userId: String
    var registeredAt: Date
}

/// Event participant row used by mentor event management.
/// The registration is authoritative; the user profile is optional because a
/// profile fetch may fail or the account may no longer exist.
struct EventParticipant: Identifiable, Equatable {
    var id: String { registration.registrationId }
    var registration: EventRegistrationModel
    var user: UserModel?
}
