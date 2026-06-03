import FirebaseFirestore
import Foundation

final class ScheduleService {
    static let shared = ScheduleService()

    private let db = Firestore.firestore()

    private init() {}

    func listenActivities(for user: UserModel, onChange: @escaping (Result<[ActivityModel], Error>) -> Void) -> ListenerRegistration {
        let collection = db.collection(FirestoreCollections.activities)

        let query: Query
        if user.role == .admin {
            query = collection
        } else if user.role == .mentor {
            query = collection.whereField("mentorId", isEqualTo: user.uid)
        } else {
            query = collection.whereField("assignedUserIds", arrayContains: user.uid)
        }

        return query.addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            let activities = snapshot?.documents.map { document in
                self.decodeActivity(id: document.documentID, data: document.data())
            }
            .sorted { $0.startTime < $1.startTime } ?? []
            onChange(.success(activities))
        }
    }

    func listenAssignments(for user: UserModel, onChange: @escaping (Result<[ActivityAssignmentModel], Error>) -> Void) -> ListenerRegistration {
        let collection = db.collection(FirestoreCollections.activityAssignments)

        let query: Query
        if user.role == .admin {
            query = collection
        } else if user.role == .mentor {
            query = collection.whereField("mentorId", isEqualTo: user.uid)
        } else {
            query = collection.whereField("userId", isEqualTo: user.uid)
        }

        return query.addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            let assignments = snapshot?.documents.map { document in
                self.decodeAssignment(id: document.documentID, data: document.data())
            } ?? []
            onChange(.success(assignments))
        }
    }

    func listenEvents(onChange: @escaping (Result<[EventModel], Error>) -> Void) -> ListenerRegistration {
        db.collection(FirestoreCollections.events)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                let events = snapshot?.documents.map { document in
                    self.decodeEvent(id: document.documentID, data: document.data())
                }
                .sorted { $0.startDate < $1.startDate } ?? []
                onChange(.success(events))
            }
    }

    func listenEventRegistrations(for user: UserModel, onChange: @escaping (Result<[EventRegistrationModel], Error>) -> Void) -> ListenerRegistration {
        let collection = db.collection(FirestoreCollections.eventRegistrations)

        let query: Query
        if user.role == .admin {
            query = collection
        } else if user.role == .mentor {
            query = collection.whereField("mentorId", isEqualTo: user.uid)
        } else {
            query = collection.whereField("userId", isEqualTo: user.uid)
        }

        return query.addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            let registrations = snapshot?.documents.map { document in
                self.decodeRegistration(id: document.documentID, data: document.data())
            } ?? []
            onChange(.success(registrations))
        }
    }

    func createActivity(title: String, description: String, date: Date, startTime: Date, endTime: Date, mentorId: String, assignedUserIds: [String]) async throws {
        guard !assignedUserIds.isEmpty else {
            throw ScheduleServiceError.emptyParticipants
        }

        let activityId = UUID().uuidString
        let now = Date()
        let activity = ActivityModel(
            activityId: activityId,
            title: title,
            description: description,
            date: date,
            startTime: startTime,
            endTime: endTime,
            mentorId: mentorId,
            assignedUserIds: assignedUserIds,
            createdAt: now,
            updatedAt: now
        )

        let batch = db.batch()
        batch.setData(encode(activity), forDocument: activityDocument(activityId))

        for userId in assignedUserIds {
            let assignment = ActivityAssignmentModel(
                assignmentId: assignmentId(activityId: activityId, userId: userId),
                activityId: activityId,
                userId: userId,
                completed: false,
                completedAt: nil,
                assignedAt: now
            )
            batch.setData(encode(assignment, mentorId: mentorId), forDocument: assignmentDocument(assignment.assignmentId))
        }

        try await batch.commit()
    }

    func updateActivity(activity: ActivityModel, title: String, description: String, date: Date, startTime: Date, endTime: Date, assignedUserIds: [String], mentorId: String) async throws {
        guard activity.mentorId == mentorId else {
            throw ScheduleServiceError.mentorRequired
        }

        guard !assignedUserIds.isEmpty else {
            throw ScheduleServiceError.emptyParticipants
        }

        let previousUserIds = Set(activity.assignedUserIds)
        let nextUserIds = Set(assignedUserIds)
        let now = Date()
        var updated = activity
        updated.title = title
        updated.description = description
        updated.date = date
        updated.startTime = startTime
        updated.endTime = endTime
        updated.assignedUserIds = assignedUserIds
        updated.updatedAt = now

        let batch = db.batch()
        batch.updateData(encode(updated), forDocument: activityDocument(activity.activityId))

        for userId in nextUserIds.subtracting(previousUserIds) {
            let id = assignmentId(activityId: activity.activityId, userId: userId)
            let assignment = ActivityAssignmentModel(
                assignmentId: id,
                activityId: activity.activityId,
                userId: userId,
                completed: false,
                completedAt: nil,
                assignedAt: now
            )
            batch.setData(encode(assignment, mentorId: mentorId), forDocument: assignmentDocument(id))
        }

        for userId in previousUserIds.subtracting(nextUserIds) {
            batch.deleteDocument(assignmentDocument(assignmentId(activityId: activity.activityId, userId: userId)))
        }

        try await batch.commit()
    }

    func deleteActivity(_ activity: ActivityModel, mentorId: String) async throws {
        guard activity.mentorId == mentorId else {
            throw ScheduleServiceError.mentorRequired
        }

        let batch = db.batch()
        batch.deleteDocument(activityDocument(activity.activityId))
        for userId in activity.assignedUserIds {
            batch.deleteDocument(assignmentDocument(assignmentId(activityId: activity.activityId, userId: userId)))
        }
        try await batch.commit()
    }

    func updateCompletion(activityId: String, userId: String, completed: Bool) async throws {
        try await assignmentDocument(assignmentId(activityId: activityId, userId: userId)).updateData([
            "completed": completed,
            "completedAt": completed ? Timestamp(date: Date()) : NSNull()
        ])
    }

    func createEvent(title: String, description: String, imageURL: String?, location: String, startDate: Date, endDate: Date, capacity: Int, registrationDeadline: Date, mentorId: String) async throws {
        guard capacity > 0 else {
            throw ScheduleServiceError.invalidCapacity
        }

        let eventId = UUID().uuidString
        let now = Date()
        let event = EventModel(
            eventId: eventId,
            title: title,
            description: description,
            imageURL: imageURL,
            location: location,
            startDate: startDate,
            endDate: endDate,
            capacity: capacity,
            registrationDeadline: registrationDeadline,
            mentorId: mentorId,
            participantCount: 0,
            createdAt: now,
            updatedAt: now
        )

        try await eventDocument(eventId).setData(encode(event))
    }

    func updateEvent(_ event: EventModel, title: String, description: String, imageURL: String?, location: String, startDate: Date, endDate: Date, capacity: Int, registrationDeadline: Date, mentorId: String) async throws {
        guard event.mentorId == mentorId else {
            throw ScheduleServiceError.mentorRequired
        }

        guard capacity >= event.participantCount else {
            throw ScheduleServiceError.invalidCapacity
        }

        try await eventDocument(event.eventId).updateData([
            "title": title,
            "description": description,
            "imageURL": imageURL as Any,
            "location": location,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "capacity": capacity,
            "registrationDeadline": Timestamp(date: registrationDeadline),
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func deleteEvent(_ event: EventModel, mentorId: String) async throws {
        guard event.mentorId == mentorId else {
            throw ScheduleServiceError.mentorRequired
        }

        let registrations = try await fetchRegistrations(eventId: event.eventId)
        let batch = db.batch()
        batch.deleteDocument(eventDocument(event.eventId))
        for registration in registrations {
            batch.deleteDocument(registrationDocument(registration.registrationId))
        }
        try await batch.commit()
    }

    func registerForEvent(event: EventModel, userId: String) async throws {
        let registrationId = registrationId(eventId: event.eventId, userId: userId)
        try await db.runVoidAsyncTransaction { transaction in
            let eventRef = self.eventDocument(event.eventId)
            let registrationRef = self.registrationDocument(registrationId)
            let userRef = self.db.collection(FirestoreCollections.users).document(userId)

            let eventSnapshot = try transaction.getDocument(eventRef)
            let registrationSnapshot = try transaction.getDocument(registrationRef)
            guard let eventData = eventSnapshot.data() else {
                throw ScheduleServiceError.eventNotFound
            }

            guard !registrationSnapshot.exists else {
                throw ScheduleServiceError.alreadyRegistered
            }

            guard Date() <= eventData.date("registrationDeadline") else {
                throw ScheduleServiceError.registrationClosed
            }

            guard eventData.int("participantCount") < eventData.int("capacity") else {
                throw ScheduleServiceError.eventFull
            }

            transaction.setData([
                "registrationId": registrationId,
                "eventId": event.eventId,
                "userId": userId,
                "mentorId": eventData.string("mentorId"),
                "registeredAt": Timestamp(date: Date())
            ], forDocument: registrationRef)

            transaction.updateData([
                "participantCount": FieldValue.increment(Int64(1))
            ], forDocument: eventRef)

            transaction.updateData([
                "registeredEvents": FieldValue.arrayUnion([event.eventId])
            ], forDocument: userRef)
        }
    }

    func cancelRegistration(eventId: String, userId: String) async throws {
        let registrationId = registrationId(eventId: eventId, userId: userId)
        try await db.runVoidAsyncTransaction { transaction in
            let eventRef = self.eventDocument(eventId)
            let registrationRef = self.registrationDocument(registrationId)
            let userRef = self.db.collection(FirestoreCollections.users).document(userId)
            let registrationSnapshot = try transaction.getDocument(registrationRef)

            guard registrationSnapshot.exists else {
                throw ScheduleServiceError.registrationNotFound
            }

            transaction.deleteDocument(registrationRef)
            transaction.updateData([
                "participantCount": FieldValue.increment(Int64(-1))
            ], forDocument: eventRef)
            transaction.updateData([
                "registeredEvents": FieldValue.arrayRemove([eventId])
            ], forDocument: userRef)
        }
    }

    func removeParticipant(eventId: String, userId: String, mentorId: String) async throws {
        let event = try await fetchEvent(eventId: eventId)
        guard event.mentorId == mentorId else {
            throw ScheduleServiceError.mentorRequired
        }
        try await cancelRegistration(eventId: eventId, userId: userId)
    }

    func fetchMentorParticipantCandidates(mentorId: String) async throws -> [UserModel] {
        let groups = try await GroupService.shared.fetchMentorGroups(mentorId: mentorId)
        let memberIds = Array(Set(groups.flatMap(\.members))).sorted()
        var users: [UserModel] = []

        for userId in memberIds {
            if let user = try? await UserService.shared.fetchUser(uid: userId) {
                users.append(user)
            }
        }

        return users.sorted { $0.fullName < $1.fullName }
    }

    func fetchEventParticipants(eventId: String) async throws -> [EventParticipant] {
        let registrations = try await fetchRegistrations(eventId: eventId)
        var participants: [EventParticipant] = []

        for registration in registrations {
            let user = try? await UserService.shared.fetchUser(uid: registration.userId)
            participants.append(EventParticipant(registration: registration, user: user))
        }

        return participants.sorted {
            ($0.user?.fullName ?? "") < ($1.user?.fullName ?? "")
        }
    }

    private func fetchEvent(eventId: String) async throws -> EventModel {
        let snapshot = try await eventDocument(eventId).getDocument()
        guard let data = snapshot.data() else {
            throw ScheduleServiceError.eventNotFound
        }
        return decodeEvent(id: snapshot.documentID, data: data)
    }

    private func fetchRegistrations(eventId: String) async throws -> [EventRegistrationModel] {
        let snapshot = try await db.collection(FirestoreCollections.eventRegistrations)
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments()

        return snapshot.documents.map { document in
            decodeRegistration(id: document.documentID, data: document.data())
        }
    }

    private func activityDocument(_ activityId: String) -> DocumentReference {
        db.collection(FirestoreCollections.activities).document(activityId)
    }

    private func assignmentDocument(_ assignmentId: String) -> DocumentReference {
        db.collection(FirestoreCollections.activityAssignments).document(assignmentId)
    }

    private func eventDocument(_ eventId: String) -> DocumentReference {
        db.collection(FirestoreCollections.events).document(eventId)
    }

    private func registrationDocument(_ registrationId: String) -> DocumentReference {
        db.collection(FirestoreCollections.eventRegistrations).document(registrationId)
    }

    private func assignmentId(activityId: String, userId: String) -> String {
        "\(activityId)_\(userId)"
    }

    private func registrationId(eventId: String, userId: String) -> String {
        "\(eventId)_\(userId)"
    }

    private func encode(_ activity: ActivityModel) -> [String: Any] {
        [
            "activityId": activity.activityId,
            "title": activity.title,
            "description": activity.description,
            "date": Timestamp(date: activity.date),
            "startTime": Timestamp(date: activity.startTime),
            "endTime": Timestamp(date: activity.endTime),
            "mentorId": activity.mentorId,
            "assignedUserIds": activity.assignedUserIds,
            "createdAt": Timestamp(date: activity.createdAt),
            "updatedAt": Timestamp(date: activity.updatedAt)
        ]
    }

    private func encode(_ assignment: ActivityAssignmentModel, mentorId: String) -> [String: Any] {
        [
            "assignmentId": assignment.assignmentId,
            "activityId": assignment.activityId,
            "userId": assignment.userId,
            "mentorId": mentorId,
            "completed": assignment.completed,
            "completedAt": assignment.completedAt.map(Timestamp.init(date:)) as Any,
            "assignedAt": Timestamp(date: assignment.assignedAt)
        ]
    }

    private func encode(_ event: EventModel) -> [String: Any] {
        [
            "eventId": event.eventId,
            "title": event.title,
            "description": event.description,
            "imageURL": event.imageURL as Any,
            "location": event.location,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "capacity": event.capacity,
            "registrationDeadline": Timestamp(date: event.registrationDeadline),
            "mentorId": event.mentorId,
            "participantCount": event.participantCount,
            "createdAt": Timestamp(date: event.createdAt),
            "updatedAt": Timestamp(date: event.updatedAt)
        ]
    }

    private func decodeActivity(id: String, data: [String: Any]) -> ActivityModel {
        ActivityModel(
            activityId: data.string("activityId", default: id),
            title: data.string("title"),
            description: data.string("description"),
            date: data.date("date"),
            startTime: data.date("startTime"),
            endTime: data.date("endTime"),
            mentorId: data.string("mentorId"),
            assignedUserIds: data.stringArray("assignedUserIds"),
            createdAt: data.date("createdAt"),
            updatedAt: data.date("updatedAt")
        )
    }

    private func decodeAssignment(id: String, data: [String: Any]) -> ActivityAssignmentModel {
        let completedAt: Date?
        if data["completedAt"] is Timestamp {
            completedAt = data.date("completedAt")
        } else {
            completedAt = nil
        }

        return ActivityAssignmentModel(
            assignmentId: data.string("assignmentId", default: id),
            activityId: data.string("activityId"),
            userId: data.string("userId"),
            completed: data.bool("completed"),
            completedAt: completedAt,
            assignedAt: data.date("assignedAt")
        )
    }

    private func decodeEvent(id: String, data: [String: Any]) -> EventModel {
        EventModel(
            eventId: data.string("eventId", default: id),
            title: data.string("title"),
            description: data.string("description"),
            imageURL: data["imageURL"] as? String,
            location: data.string("location"),
            startDate: data.date("startDate"),
            endDate: data.date("endDate"),
            capacity: data.int("capacity"),
            registrationDeadline: data.date("registrationDeadline"),
            mentorId: data.string("mentorId", default: data.string("createdBy")),
            participantCount: data.int("participantCount", default: data.stringArray("attendees").count),
            createdAt: data.date("createdAt", default: data.date("startDate")),
            updatedAt: data.date("updatedAt", default: data.date("createdAt", default: data.date("startDate")))
        )
    }

    private func decodeRegistration(id: String, data: [String: Any]) -> EventRegistrationModel {
        EventRegistrationModel(
            registrationId: data.string("registrationId", default: id),
            eventId: data.string("eventId"),
            userId: data.string("userId"),
            registeredAt: data.date("registeredAt")
        )
    }
}

enum ScheduleServiceError: LocalizedError {
    case emptyParticipants
    case mentorRequired
    case invalidCapacity
    case eventNotFound
    case eventFull
    case registrationClosed
    case alreadyRegistered
    case registrationNotFound

    var errorDescription: String? {
        switch self {
        case .emptyParticipants:
            "Select at least one participant."
        case .mentorRequired:
            "Only the mentor who created this item can manage it."
        case .invalidCapacity:
            "Capacity must be valid for the current participants."
        case .eventNotFound:
            "Event was not found."
        case .eventFull:
            "This event is already full."
        case .registrationClosed:
            "Registration is already closed."
        case .alreadyRegistered:
            "You are already registered for this event."
        case .registrationNotFound:
            "Registration was not found."
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
