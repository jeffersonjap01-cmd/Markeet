import FirebaseFirestore
import Foundation

@MainActor
final class EventViewModel: ObservableObject {
    @Published var activities: [ActivityModel] = []
    @Published var assignments: [ActivityAssignmentModel] = []
    @Published var events: [EventModel] = []
    @Published var registrations: [EventRegistrationModel] = []
    @Published var participantCandidates: [UserModel] = []
    @Published var eventParticipants: [EventParticipant] = []
    @Published var selectedDate = Date()
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    private var listeners: [ListenerRegistration] = []

    var selectedDateActivities: [ScheduledActivity] {
        scheduledActivities(on: selectedDate)
    }

    var visibleEvents: [EventModel] {
        let now = Date()
        return events
            .filter { $0.endDate >= now }
            .sorted { $0.startDate < $1.startDate }
    }

    var mentorManageableEvents: [EventModel] {
        events.sorted {
            if $0.endDate == $1.endDate {
                return $0.title < $1.title
            }
            return $0.endDate > $1.endDate
        }
    }

    var myRegisteredEvents: [EventModel] {
        let eventIds = Set(registrations.map(\.eventId))
        return events
            .filter { eventIds.contains($0.eventId) }
            .sorted { $0.startDate < $1.startDate }
    }

    func start(session: SessionManager) {
        stop()
        guard let user = session.currentUser else {
            errorMessage = ScheduleViewModelError.missingUser.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        listeners.append(
            ScheduleService.shared.listenActivities(for: user) { [weak self] result in
                Task { @MainActor in
                    self?.applyActivities(result)
                }
            }
        )

        listeners.append(
            ScheduleService.shared.listenAssignments(for: user) { [weak self] result in
                Task { @MainActor in
                    self?.applyAssignments(result)
                }
            }
        )

        listeners.append(
            ScheduleService.shared.listenEvents { [weak self] result in
                Task { @MainActor in
                    self?.applyEvents(result)
                }
            }
        )

        listeners.append(
            ScheduleService.shared.listenEventRegistrations(for: user) { [weak self] result in
                Task { @MainActor in
                    self?.applyRegistrations(result)
                }
            }
        )

        if user.role == .mentor {
            Task {
                await loadParticipantCandidates(mentorId: user.uid)
            }
        }
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    func activitiesContainPendingItem(on date: Date) -> Bool {
        guard !Calendar.current.startOfDay(for: date).isBeforeToday else {
            return false
        }

        let items = scheduledActivities(on: date)
        return items.contains { !$0.isCompleted }
    }

    func scheduledActivities(on date: Date) -> [ScheduledActivity] {
        let calendar = Calendar.current
        let assignmentByActivityId = Dictionary(grouping: assignments, by: \.activityId)
            .compactMapValues { $0.first }

        return activities
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .map { activity in
                ScheduledActivity(
                    activity: activity,
                    assignment: assignmentByActivityId[activity.activityId],
                    mentor: nil
                )
            }
            .sorted { $0.activity.startTime < $1.activity.startTime }
    }

    func createActivity(title: String, description: String, date: Date, startTime: Date, endTime: Date, participantIds: [String], session: SessionManager) async {
        await run {
            guard let user = session.currentUser, user.role == .mentor else {
                throw ScheduleViewModelError.mentorRequired
            }

            try await ScheduleService.shared.createActivity(
                title: title,
                description: description,
                date: date,
                startTime: startTime,
                endTime: endTime,
                mentorId: user.uid,
                assignedUserIds: participantIds
            )
            self.successMessage = "Activity created."
        }
    }

    func updateActivity(_ activity: ActivityModel, title: String, description: String, date: Date, startTime: Date, endTime: Date, participantIds: [String], session: SessionManager) async {
        await run {
            guard let user = session.currentUser, user.role == .mentor else {
                throw ScheduleViewModelError.mentorRequired
            }

            try await ScheduleService.shared.updateActivity(
                activity: activity,
                title: title,
                description: description,
                date: date,
                startTime: startTime,
                endTime: endTime,
                assignedUserIds: participantIds,
                mentorId: user.uid
            )
            self.successMessage = "Activity updated."
        }
    }

    func deleteActivity(_ activity: ActivityModel, session: SessionManager) async {
        await run {
            guard let user = session.currentUser, user.role == .mentor else {
                throw ScheduleViewModelError.mentorRequired
            }

            try await ScheduleService.shared.deleteActivity(activity, mentorId: user.uid)
            self.successMessage = "Activity deleted."
        }
    }

    func updateCompletion(_ item: ScheduledActivity, completed: Bool, session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw ScheduleViewModelError.missingUser
            }

            try await ScheduleService.shared.updateCompletion(
                activityId: item.activity.activityId,
                userId: user.uid,
                completed: completed
            )
            self.successMessage = completed ? "Activity completed." : "Activity marked incomplete."
        }
    }

    func createEvent(title: String, description: String, imageURL: String?, location: String, startDate: Date, endDate: Date, capacity: Int, registrationDeadline: Date, session: SessionManager) async {
        await run {
            guard let user = session.currentUser, user.role == .mentor else {
                throw ScheduleViewModelError.mentorRequired
            }

            try await ScheduleService.shared.createEvent(
                title: title,
                description: description,
                imageURL: imageURL,
                location: location,
                startDate: startDate,
                endDate: endDate,
                capacity: capacity,
                registrationDeadline: registrationDeadline,
                mentorId: user.uid
            )
            self.successMessage = "Event created."
        }
    }

    func updateEvent(_ event: EventModel, title: String, description: String, imageURL: String?, location: String, startDate: Date, endDate: Date, capacity: Int, registrationDeadline: Date, session: SessionManager) async {
        await run {
            guard let user = session.currentUser, user.role == .mentor else {
                throw ScheduleViewModelError.mentorRequired
            }

            try await ScheduleService.shared.updateEvent(
                event,
                title: title,
                description: description,
                imageURL: imageURL,
                location: location,
                startDate: startDate,
                endDate: endDate,
                capacity: capacity,
                registrationDeadline: registrationDeadline,
                mentorId: user.uid
            )
            self.successMessage = "Event updated."
        }
    }

    func deleteEvent(_ event: EventModel, session: SessionManager) async {
        await run {
            guard let user = session.currentUser, user.role == .mentor else {
                throw ScheduleViewModelError.mentorRequired
            }

            try await ScheduleService.shared.deleteEvent(event, mentorId: user.uid)
            self.successMessage = "Event deleted."
        }
    }

    func register(for event: EventModel, session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw ScheduleViewModelError.missingUser
            }

            guard user.role != .mentor else {
                throw ScheduleViewModelError.mentorCannotRegister
            }

            try await ScheduleService.shared.registerForEvent(event: event, userId: user.uid)
            await session.reloadCurrentUser()
            self.successMessage = "Registered for event."
        }
    }

    func cancelRegistration(for event: EventModel, session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw ScheduleViewModelError.missingUser
            }

            try await ScheduleService.shared.cancelRegistration(eventId: event.eventId, userId: user.uid)
            await session.reloadCurrentUser()
            self.successMessage = "Registration cancelled."
        }
    }

    func loadParticipants(for event: EventModel) async {
        await run {
            self.eventParticipants = try await ScheduleService.shared.fetchEventParticipants(eventId: event.eventId)
        }
    }

    func removeParticipant(_ participant: EventParticipant, from event: EventModel, session: SessionManager) async {
        await run {
            guard let user = session.currentUser, user.role == .mentor else {
                throw ScheduleViewModelError.mentorRequired
            }

            try await ScheduleService.shared.removeParticipant(
                eventId: event.eventId,
                userId: participant.registration.userId,
                mentorId: user.uid
            )
            self.eventParticipants.removeAll { $0.id == participant.id }
            self.successMessage = "Participant removed."
        }
    }

    func isRegistered(for event: EventModel) -> Bool {
        registrations.contains { $0.eventId == event.eventId }
    }

    private func loadParticipantCandidates(mentorId: String) async {
        do {
            participantCandidates = try await ScheduleService.shared.fetchMentorParticipantCandidates(mentorId: mentorId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyActivities(_ result: Result<[ActivityModel], Error>) {
        isLoading = false
        switch result {
        case .success(let activities):
            self.activities = activities
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func applyAssignments(_ result: Result<[ActivityAssignmentModel], Error>) {
        switch result {
        case .success(let assignments):
            self.assignments = assignments
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func applyEvents(_ result: Result<[EventModel], Error>) {
        switch result {
        case .success(let events):
            self.events = events
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func applyRegistrations(_ result: Result<[EventRegistrationModel], Error>) {
        switch result {
        case .success(let registrations):
            self.registrations = registrations
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func run(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum ScheduleViewModelError: LocalizedError {
    case missingUser
    case mentorRequired
    case mentorCannotRegister

    var errorDescription: String? {
        switch self {
        case .missingUser:
            "User session is missing."
        case .mentorRequired:
            "Only mentors can manage schedule items."
        case .mentorCannotRegister:
            "Mentors manage events and do not register for them."
        }
    }
}

private extension Date {
    var isBeforeToday: Bool {
        self < Calendar.current.startOfDay(for: Date())
    }
}
