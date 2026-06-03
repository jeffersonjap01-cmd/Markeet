import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = EventViewModel()
    @State private var displayedMonth = Date()
    @State private var showingActivityEditor = false
    @State private var showingEventEditor = false
    @State private var editingActivity: ActivityModel?
    @State private var editingEvent: EventModel?

    private var isMentor: Bool {
        session.currentUser?.role == .mentor
    }

    var body: some View {
        NavigationStack {
            List {
                messageSection
                calendarSection
                activitiesSection
                eventsSection
                if !isMentor {
                    registeredEventsSection
                }
            }
            .navigationTitle("Jadwal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isMentor {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            editingActivity = nil
                            showingActivityEditor = true
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                        }

                        Button {
                            editingEvent = nil
                            showingEventEditor = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.activities.isEmpty && viewModel.events.isEmpty {
                    ProgressView()
                }
            }
            .onAppear {
                viewModel.start(session: session)
            }
            .onDisappear {
                viewModel.stop()
            }
            .sheet(isPresented: $showingActivityEditor) {
                ActivityEditorView(
                    activity: editingActivity,
                    participants: viewModel.participantCandidates
                ) { title, description, date, startTime, endTime, participantIds in
                    if let editingActivity {
                        await viewModel.updateActivity(
                            editingActivity,
                            title: title,
                            description: description,
                            date: date,
                            startTime: startTime,
                            endTime: endTime,
                            participantIds: participantIds,
                            session: session
                        )
                    } else {
                        await viewModel.createActivity(
                            title: title,
                            description: description,
                            date: date,
                            startTime: startTime,
                            endTime: endTime,
                            participantIds: participantIds,
                            session: session
                        )
                    }
                }
            }
            .sheet(isPresented: $showingEventEditor) {
                EventEditorView(event: editingEvent) { title, description, imageURL, location, startDate, endDate, capacity, registrationDeadline in
                    if let editingEvent {
                        await viewModel.updateEvent(
                            editingEvent,
                            title: title,
                            description: description,
                            imageURL: imageURL,
                            location: location,
                            startDate: startDate,
                            endDate: endDate,
                            capacity: capacity,
                            registrationDeadline: registrationDeadline,
                            session: session
                        )
                    } else {
                        await viewModel.createEvent(
                            title: title,
                            description: description,
                            imageURL: imageURL,
                            location: location,
                            startDate: startDate,
                            endDate: endDate,
                            capacity: capacity,
                            registrationDeadline: registrationDeadline,
                            session: session
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        if let successMessage = viewModel.successMessage {
            Text(successMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.success)
        }

        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.error)
        }
    }

    private var calendarSection: some View {
        Section {
            VStack(spacing: 16) {
                HStack {
                    Button {
                        displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button {
                        displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }

                HStack {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(monthDays(), id: \.self) { date in
                        if let date {
                            dayCell(date)
                        } else {
                            Color.clear.frame(height: 44)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var activitiesSection: some View {
        Section(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted)) {
            if viewModel.selectedDateActivities.isEmpty {
                Text("No activities for this date.")
                    .foregroundColor(AppTheme.textSecondary)
            }

            ForEach(viewModel.selectedDateActivities) { item in
                if isMentor {
                    NavigationLink {
                        ActivityParticipantStatusView(activity: item.activity, viewModel: viewModel)
                    } label: {
                        activityRow(item)
                    }
                } else {
                    activityRow(item)
                }
            }
        }
    }

    private var eventsSection: some View {
        Section(isMentor ? "Event List" : "Available Events") {
            if viewModel.visibleEvents.isEmpty {
                Text("No events available.")
                    .foregroundColor(AppTheme.textSecondary)
            }

            ForEach(viewModel.visibleEvents) { event in
                NavigationLink {
                    EventDetailView(event: event, viewModel: viewModel)
                        .environmentObject(session)
                } label: {
                    eventRow(event)
                }
            }
        }
    }

    private var registeredEventsSection: some View {
        Section("My Registered Events") {
            if viewModel.myRegisteredEvents.isEmpty {
                Text("Registered events will appear here.")
                    .foregroundColor(AppTheme.textSecondary)
            }

            ForEach(viewModel.myRegisteredEvents) { event in
                NavigationLink {
                    EventDetailView(event: event, viewModel: viewModel)
                        .environmentObject(session)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(event.title)
                            .font(.system(size: 15, weight: .semibold))
                        Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        RoleBadge(role: event.endDate < Date() ? "Finished" : "Registered", color: event.endDate < Date() ? AppTheme.textTertiary : AppTheme.success)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let selected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        let hasDot = viewModel.activitiesContainPendingItem(on: date)

        return Button {
            viewModel.selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: selected ? .bold : .regular))
                    .foregroundColor(selected ? .white : (isCurrentMonth ? AppTheme.textPrimary : AppTheme.textTertiary))

                Circle()
                    .fill(hasDot ? AppTheme.error : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(selected ? AppTheme.primary : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func activityRow(_ item: ScheduledActivity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.activity.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                RoleBadge(role: item.isCompleted ? "Completed" : "Pending", color: item.isCompleted ? AppTheme.success : AppTheme.error)
            }

            Text(item.activity.description)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)

            Label("\(item.activity.startTime.formatted(date: .omitted, time: .shortened)) - \(item.activity.endTime.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textTertiary)

            if isMentor {
                HStack {
                    Button {
                        editingActivity = item.activity
                        showingActivityEditor = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteActivity(item.activity, session: session)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .font(.system(size: 12, weight: .medium))
            } else {
                Toggle("Completed", isOn: Binding(
                    get: { item.isCompleted },
                    set: { completed in
                        Task {
                            await viewModel.updateCompletion(item, completed: completed, session: session)
                        }
                    }
                ))
                .toggleStyle(.switch)
            }
        }
        .padding(.vertical, 6)
    }

    private func eventRow(_ event: EventModel) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(event.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                RoleBadge(role: "\(event.participantCount)/\(event.capacity)", color: event.isRegistrationOpen ? AppTheme.success : AppTheme.textTertiary)
            }

            Text(event.location)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)

            Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(.vertical, 5)
    }

    private func monthDays() -> [Date?] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let monthStart = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let leading = calendar.component(.weekday, from: monthStart) - 1
        let days = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: monthStart) }
        return Array(repeating: nil, count: leading) + days
    }
}

private struct ActivityEditorView: View {
    var activity: ActivityModel?
    let participants: [UserModel]
    let onSave: (String, String, Date, Date, Date, [String]) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedParticipantIds: Set<String>

    init(activity: ActivityModel?, participants: [UserModel], onSave: @escaping (String, String, Date, Date, Date, [String]) async -> Void) {
        self.activity = activity
        self.participants = participants
        self.onSave = onSave
        _title = State(initialValue: activity?.title ?? "")
        _description = State(initialValue: activity?.description ?? "")
        _date = State(initialValue: activity?.date ?? Date())
        _startTime = State(initialValue: activity?.startTime ?? Date())
        _endTime = State(initialValue: activity?.endTime ?? Date().addingTimeInterval(3600))
        _selectedParticipantIds = State(initialValue: Set(activity?.assignedUserIds ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...5)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)

                Section("Assigned Participants") {
                    if participants.isEmpty {
                        Text("No members found in your communities.")
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    ForEach(participants) { participant in
                        Button {
                            if selectedParticipantIds.contains(participant.uid) {
                                selectedParticipantIds.remove(participant.uid)
                            } else {
                                selectedParticipantIds.insert(participant.uid)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(participant.fullName)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(participant.email)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: selectedParticipantIds.contains(participant.uid) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedParticipantIds.contains(participant.uid) ? AppTheme.primary : AppTheme.textTertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(activity == nil ? "New Activity" : "Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await onSave(
                                title.trimmingCharacters(in: .whitespacesAndNewlines),
                                description.trimmingCharacters(in: .whitespacesAndNewlines),
                                date,
                                combine(date: date, time: startTime),
                                combine(date: date, time: endTime),
                                Array(selectedParticipantIds)
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedParticipantIds.isEmpty)
                }
            }
        }
    }

    private func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) ?? date
    }
}

private struct ActivityParticipantStatusView: View {
    let activity: ActivityModel
    @ObservedObject var viewModel: EventViewModel

    private var assignedUsers: [UserModel] {
        activity.assignedUserIds.compactMap { userId in
            viewModel.participantCandidates.first { $0.uid == userId }
        }
        .sorted { $0.fullName < $1.fullName }
    }

    var body: some View {
        List {
            Section("Activity") {
                Text(activity.description)
                LabeledContent("Date", value: activity.date.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Time", value: "\(activity.startTime.formatted(date: .omitted, time: .shortened)) - \(activity.endTime.formatted(date: .omitted, time: .shortened))")
            }

            Section("Participant Completion") {
                if assignedUsers.isEmpty {
                    Text("No assigned participants.")
                        .foregroundColor(AppTheme.textSecondary)
                }

                ForEach(assignedUsers) { user in
                    let assignment = viewModel.assignments.first {
                        $0.activityId == activity.activityId && $0.userId == user.uid
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(user.fullName)
                                .font(.system(size: 14, weight: .semibold))
                            Text(user.email)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        RoleBadge(
                            role: assignment?.completed == true ? "Completed" : "Pending",
                            color: assignment?.completed == true ? AppTheme.success : AppTheme.error
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(activity.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EventEditorView: View {
    var event: EventModel?
    let onSave: (String, String, String?, String, Date, Date, Int, Date) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var imageURL: String
    @State private var location: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var capacity: Int
    @State private var registrationDeadline: Date

    init(event: EventModel?, onSave: @escaping (String, String, String?, String, Date, Date, Int, Date) async -> Void) {
        self.event = event
        self.onSave = onSave
        _title = State(initialValue: event?.title ?? "")
        _description = State(initialValue: event?.description ?? "")
        _imageURL = State(initialValue: event?.imageURL ?? "")
        _location = State(initialValue: event?.location ?? "")
        _startDate = State(initialValue: event?.startDate ?? Date())
        _endDate = State(initialValue: event?.endDate ?? Date().addingDays(1))
        _capacity = State(initialValue: event?.capacity ?? 30)
        _registrationDeadline = State(initialValue: event?.registrationDeadline ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...5)
                TextField("Image URL", text: $imageURL)
                TextField("Location", text: $location)
                DatePicker("Start Date", selection: $startDate)
                DatePicker("End Date", selection: $endDate)
                DatePicker("Registration Deadline", selection: $registrationDeadline)
                Stepper("Capacity: \(capacity)", value: $capacity, in: 1...500)
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await onSave(
                                title.trimmingCharacters(in: .whitespacesAndNewlines),
                                description.trimmingCharacters(in: .whitespacesAndNewlines),
                                imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : imageURL,
                                location.trimmingCharacters(in: .whitespacesAndNewlines),
                                startDate,
                                endDate,
                                capacity,
                                registrationDeadline
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || endDate < startDate)
                }
            }
        }
    }
}

private struct EventDetailView: View {
    let event: EventModel
    @ObservedObject var viewModel: EventViewModel
    @EnvironmentObject private var session: SessionManager
    @State private var showingEdit = false

    private var isMentorOwner: Bool {
        session.currentUser?.uid == event.mentorId && session.currentUser?.role == .mentor
    }

    var body: some View {
        List {
            Section("Event") {
                if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Rectangle().fill(AppTheme.primary.opacity(0.1))
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                }

                Text(event.description)
                LabeledContent("Location", value: event.location)
                LabeledContent("Starts", value: event.startDate.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Ends", value: event.endDate.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Registration Deadline", value: event.registrationDeadline.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Participants", value: "\(event.participantCount)/\(event.capacity)")
            }

            if isMentorOwner {
                mentorActions
                participantsSection
            } else if session.currentUser?.role != .mentor {
                memberActions
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if isMentorOwner {
                await viewModel.loadParticipants(for: event)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EventEditorView(event: event) { title, description, imageURL, location, startDate, endDate, capacity, registrationDeadline in
                await viewModel.updateEvent(
                    event,
                    title: title,
                    description: description,
                    imageURL: imageURL,
                    location: location,
                    startDate: startDate,
                    endDate: endDate,
                    capacity: capacity,
                    registrationDeadline: registrationDeadline,
                    session: session
                )
            }
        }
    }

    private var mentorActions: some View {
        Section {
            Button {
                showingEdit = true
            } label: {
                Label("Edit Event", systemImage: "pencil")
            }

            Button(role: .destructive) {
                Task {
                    await viewModel.deleteEvent(event, session: session)
                }
            } label: {
                Label("Delete Event", systemImage: "trash")
            }
        }
    }

    private var memberActions: some View {
        Section {
            if viewModel.isRegistered(for: event) {
                Button(role: .destructive) {
                    Task {
                        await viewModel.cancelRegistration(for: event, session: session)
                    }
                } label: {
                    Label("Cancel Registration", systemImage: "xmark.circle")
                }
            } else {
                Button {
                    Task {
                        await viewModel.register(for: event, session: session)
                    }
                } label: {
                    Label("Register", systemImage: "checkmark.circle")
                }
                .disabled(!event.isRegistrationOpen)
            }
        }
    }

    private var participantsSection: some View {
        Section("Participants") {
            if viewModel.eventParticipants.isEmpty {
                Text("No participants yet.")
                    .foregroundColor(AppTheme.textSecondary)
            }

            ForEach(viewModel.eventParticipants) { participant in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(participant.user?.fullName ?? participant.registration.userId)
                            .font(.system(size: 14, weight: .semibold))
                        Text(participant.user?.email ?? "Unknown email")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        Text(participant.registration.registeredAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textTertiary)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        Task {
                            await viewModel.removeParticipant(participant, from: event, session: session)
                        }
                    } label: {
                        Image(systemName: "person.fill.xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    ScheduleView()
        .environmentObject(SessionManager())
}
