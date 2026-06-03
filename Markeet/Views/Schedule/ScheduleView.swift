import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = EventViewModel()
    @State private var visibleMonth = Date()
    @State private var showingActivityEditor = false
    @State private var showingEventEditor = false
    @State private var editingActivity: ActivityModel?
    @State private var editingEvent: EventModel?

    private var isMentor: Bool {
        session.currentUser?.role == .mentor
    }

    private var isAdmin: Bool {
        session.currentUser?.role == .admin
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if session.currentUser == nil {
                    EmptyStateView(
                        icon: "calendar",
                        title: "Belum Masuk",
                        subtitle: "Silakan login untuk melihat jadwal kamu."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            scheduleHeader
                            messageSection
                            calendarCard
                            activitySection
                            eventSection
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, 110)
                    }
                }

                if viewModel.isLoading {
                    LoadingOverlay(message: "Memuat jadwal...")
                }
            }
            .navigationTitle("Jadwal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isMentor {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            editingActivity = nil
                            showingActivityEditor = true
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                        }
                        .accessibilityLabel("Tambah Aktivitas")

                        Button {
                            editingEvent = nil
                            showingEventEditor = true
                        } label: {
                            Image(systemName: "megaphone")
                        }
                        .accessibilityLabel("Tambah Event")
                    }
                }
            }
            .onAppear {
                visibleMonth = viewModel.selectedDate
                viewModel.start(session: session)
            }
            .onDisappear {
                viewModel.stop()
            }
            .sheet(isPresented: $showingActivityEditor) {
                ActivityEditorView(
                    viewModel: viewModel,
                    activity: editingActivity
                )
                .environmentObject(session)
            }
            .sheet(isPresented: $showingEventEditor) {
                ScheduleEventEditorView(
                    viewModel: viewModel,
                    event: editingEvent
                )
                .environmentObject(session)
            }
        }
    }

    private var scheduleHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isMentor ? "Kelola aktivitas dan event" : "Aktivitas kamu hari ini")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(isMentor ? "Buat jadwal untuk member komunitasmu dan pantau peserta event." : "Pilih tanggal untuk melihat aktivitas, lalu daftar event yang tersedia.")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(AppTheme.primaryGradient)
            }

            if isMentor {
                HStack(spacing: AppTheme.Spacing.sm) {
                    scheduleActionButton(title: "Aktivitas", icon: "plus.circle.fill") {
                        editingActivity = nil
                        showingActivityEditor = true
                    }

                    scheduleActionButton(title: "Event", icon: "megaphone.fill") {
                        editingEvent = nil
                        showingEventEditor = true
                    }
                }
            }
        }
        .padding(.top, AppTheme.Spacing.md)
    }

    @ViewBuilder
    private var messageSection: some View {
        if let success = viewModel.successMessage {
            ScheduleMessageCard(message: success, icon: "checkmark.circle.fill", color: AppTheme.success)
        }

        if let error = viewModel.errorMessage {
            ScheduleMessageCard(message: error, icon: "exclamationmark.triangle.fill", color: AppTheme.error)
        }
    }

    private var calendarCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Button {
                    withAnimation(AppTheme.defaultAnimation) {
                        visibleMonth = Calendar.current.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.primaryGlow)
                        .clipShape(Circle())
                }

                Spacer()

                Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button {
                    withAnimation(AppTheme.defaultAnimation) {
                        visibleMonth = Calendar.current.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.primaryGlow)
                        .clipShape(Circle())
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday.prefix(2).uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textTertiary)
                        .frame(height: 20)
                }

                ForEach(monthDays) { day in
                    if let date = day.date {
                        CalendarDayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            hasPendingActivity: viewModel.activitiesContainPendingItem(on: date)
                        ) {
                            withAnimation(AppTheme.defaultAnimation) {
                                viewModel.selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 42)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: isMentor ? "Aktivitas Tanggal Ini" : "Aktivitas Saya", actionTitle: nil)

            let items = viewModel.selectedDateActivities
            if items.isEmpty {
                EmptyScheduleCard(
                    icon: "calendar.badge.clock",
                    title: "Tidak ada aktivitas",
                    subtitle: "Belum ada aktivitas untuk \(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted))."
                )
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(items) { item in
                        ActivityRow(
                            item: item,
                            isMentor: isMentor,
                            completedCount: completedCount(for: item.activity),
                            onToggle: { completed in
                                Task {
                                    await viewModel.updateCompletion(item, completed: completed, session: session)
                                }
                            },
                            onEdit: {
                                editingActivity = item.activity
                                showingActivityEditor = true
                            },
                            onDelete: {
                                Task {
                                    await viewModel.deleteActivity(item.activity, session: session)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: isMentor ? "Event Saya" : "Event Tersedia", actionTitle: nil)

            let events = isMentor || isAdmin ? viewModel.visibleEvents : viewModel.visibleEvents.filter { $0.isRegistrationOpen || viewModel.isRegistered(for: $0) }
            if events.isEmpty {
                EmptyScheduleCard(
                    icon: "megaphone",
                    title: "Belum ada event",
                    subtitle: isMentor ? "Buat event untuk mulai mengundang member." : "Event yang tersedia akan muncul di sini."
                )
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(events) { event in
                        NavigationLink {
                            ScheduleEventDetailView(
                                viewModel: viewModel,
                                event: event,
                                isMentor: isMentor,
                                onEdit: {
                                    editingEvent = event
                                    showingEventEditor = true
                                }
                            )
                            .environmentObject(session)
                        } label: {
                            ScheduleEventRow(
                                event: event,
                                isRegistered: viewModel.isRegistered(for: event),
                                isMentor: isMentor
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !isMentor && !viewModel.myRegisteredEvents.isEmpty {
                SectionHeader(title: "Event Terdaftar", actionTitle: nil)
                    .padding(.top, AppTheme.Spacing.sm)

                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(viewModel.myRegisteredEvents) { event in
                        ScheduleEventRow(event: event, isRegistered: true, isMentor: false)
                    }
                }
            }
        }
    }

    private func scheduleActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.primaryGlow)
                .cornerRadius(AppTheme.Radius.md)
        }
    }

    private var monthDays: [CalendarMonthDay] {
        CalendarMonthDay.days(for: visibleMonth)
    }

    private func completedCount(for activity: ActivityModel) -> Int {
        viewModel.assignments.filter { $0.activityId == activity.activityId && $0.completed }.count
    }
}

private struct CalendarMonthDay: Identifiable {
    let id: Int
    let date: Date?

    static func days(for month: Date) -> [CalendarMonthDay] {
        let calendar = Calendar.current
        guard
            let interval = calendar.dateInterval(of: .month, for: month),
            let daysRange = calendar.range(of: .day, in: .month, for: month)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingBlanks = firstWeekday - calendar.firstWeekday
        let normalizedBlanks = leadingBlanks >= 0 ? leadingBlanks : leadingBlanks + 7

        var output: [CalendarMonthDay] = []
        for index in 0..<normalizedBlanks {
            output.append(CalendarMonthDay(id: index, date: nil))
        }

        for day in daysRange {
            let date = calendar.date(byAdding: .day, value: day - 1, to: interval.start)
            output.append(CalendarMonthDay(id: output.count, date: date))
        }

        return output
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasPendingActivity: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)

                Circle()
                    .fill(hasPendingActivity ? AppTheme.error : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? AppTheme.primary : Color.clear)
            .cornerRadius(AppTheme.Radius.md)
        }
        .buttonStyle(.plain)
    }
}

private struct ScheduleMessageCard: View {
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.Radius.md)
    }
}

private struct EmptyScheduleCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(AppTheme.textTertiary)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.lg)
    }
}

private struct ActivityRow: View {
    let item: ScheduledActivity
    let isMentor: Bool
    let completedCount: Int
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                VStack {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(item.isCompleted ? AppTheme.success : AppTheme.primary)
                }
                .frame(width: 38, height: 38)
                .background((item.isCompleted ? AppTheme.success : AppTheme.primary).opacity(0.12))
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.activity.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    if !item.activity.description.isEmpty {
                        Text(item.activity.description)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Label(timeRange, systemImage: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                if isMentor {
                    Menu {
                        Button("Edit", systemImage: "pencil", action: onEdit)
                        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                }
            }

            if isMentor {
                HStack {
                    Label("\(item.activity.assignedUserIds.count) peserta", systemImage: "person.2.fill")
                    Spacer()
                    Label("\(completedCount) selesai", systemImage: "checkmark.seal.fill")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, 2)
            } else {
                Button {
                    onToggle(!item.isCompleted)
                } label: {
                    Text(item.isCompleted ? "Tandai Belum Selesai" : "Tandai Selesai")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(item.isCompleted ? AppTheme.primary : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(item.isCompleted ? AppTheme.primaryGlow : AppTheme.primary)
                        .cornerRadius(AppTheme.Radius.md)
                }
            }
        }
        .cardStyle()
    }

    private var timeRange: String {
        "\(item.activity.startTime.formatted(date: .omitted, time: .shortened)) - \(item.activity.endTime.formatted(date: .omitted, time: .shortened))"
    }
}

private struct ScheduleEventRow: View {
    let event: EventModel
    let isRegistered: Bool
    let isMentor: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                eventImage

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(event.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(2)

                        Spacer()

                        if isRegistered {
                            RoleBadge(role: "Terdaftar", color: AppTheme.success)
                        } else if !event.isRegistrationOpen && !isMentor {
                            RoleBadge(role: "Tutup", color: AppTheme.textTertiary)
                        }
                    }

                    Text(event.description)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)

                    VStack(alignment: .leading, spacing: 4) {
                        Label(event.location, systemImage: "mappin.and.ellipse")
                        Label(event.startDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        Label("\(event.participantCount)/\(event.capacity) peserta", systemImage: "person.2.fill")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var eventImage: some View {
        if let imageURL = event.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    iconFallback
                }
            }
            .frame(width: 62, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
        } else {
            iconFallback
                .frame(width: 62, height: 62)
        }
    }

    private var iconFallback: some View {
        ZStack {
            AppTheme.primaryGlow
            Image(systemName: "megaphone.fill")
                .font(.system(size: 22))
                .foregroundColor(AppTheme.primary)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

private struct ActivityEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @ObservedObject var viewModel: EventViewModel

    let activity: ActivityModel?

    @State private var title: String
    @State private var description: String
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedParticipantIds: Set<String>

    init(viewModel: EventViewModel, activity: ActivityModel?) {
        self.viewModel = viewModel
        self.activity = activity
        _title = State(initialValue: activity?.title ?? "")
        _description = State(initialValue: activity?.description ?? "")
        _date = State(initialValue: activity?.date ?? Date())
        _startTime = State(initialValue: activity?.startTime ?? Date())
        _endTime = State(initialValue: activity?.endTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
        _selectedParticipantIds = State(initialValue: Set(activity?.assignedUserIds ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detail Aktivitas") {
                    TextField("Judul", text: $title)
                    TextField("Deskripsi", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                    DatePicker("Tanggal", selection: $date, displayedComponents: .date)
                    DatePicker("Mulai", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Selesai", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Peserta") {
                    if viewModel.participantCandidates.isEmpty {
                        Text("Belum ada member dari komunitas mentor ini.")
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        ForEach(viewModel.participantCandidates) { user in
                            Button {
                                toggle(user.uid)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.fullName)
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text(user.email)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    if selectedParticipantIds.contains(user.uid) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.primary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(activity == nil ? "Aktivitas Baru" : "Edit Aktivitas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        Task {
                            await save()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedParticipantIds.isEmpty &&
        combinedEndTime > combinedStartTime
    }

    private var combinedStartTime: Date {
        combine(date: date, time: startTime)
    }

    private var combinedEndTime: Date {
        combine(date: date, time: endTime)
    }

    private func toggle(_ userId: String) {
        if selectedParticipantIds.contains(userId) {
            selectedParticipantIds.remove(userId)
        } else {
            selectedParticipantIds.insert(userId)
        }
    }

    private func save() async {
        let participants = Array(selectedParticipantIds)
        if let activity {
            await viewModel.updateActivity(
                activity,
                title: title,
                description: description,
                date: date,
                startTime: combinedStartTime,
                endTime: combinedEndTime,
                participantIds: participants,
                session: session
            )
        } else {
            await viewModel.createActivity(
                title: title,
                description: description,
                date: date,
                startTime: combinedStartTime,
                endTime: combinedEndTime,
                participantIds: participants,
                session: session
            )
        }
    }

    private func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components) ?? date
    }
}

private struct ScheduleEventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @ObservedObject var viewModel: EventViewModel

    let event: EventModel?

    @State private var title: String
    @State private var description: String
    @State private var imageURL: String
    @State private var location: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var capacity: Int
    @State private var registrationDeadline: Date

    init(viewModel: EventViewModel, event: EventModel?) {
        self.viewModel = viewModel
        self.event = event
        _title = State(initialValue: event?.title ?? "")
        _description = State(initialValue: event?.description ?? "")
        _imageURL = State(initialValue: event?.imageURL ?? "")
        _location = State(initialValue: event?.location ?? "")
        _startDate = State(initialValue: event?.startDate ?? Date())
        _endDate = State(initialValue: event?.endDate ?? Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date())
        _capacity = State(initialValue: max(event?.capacity ?? 30, 1))
        _registrationDeadline = State(initialValue: event?.registrationDeadline ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detail Event") {
                    TextField("Judul", text: $title)
                    TextField("Deskripsi", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                    TextField("URL Gambar", text: $imageURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField("Lokasi", text: $location)
                    Stepper("Kapasitas: \(capacity)", value: $capacity, in: minimumCapacity...500)
                }

                Section("Waktu") {
                    DatePicker("Mulai", selection: $startDate)
                    DatePicker("Selesai", selection: $endDate)
                    DatePicker("Deadline Registrasi", selection: $registrationDeadline)
                }
            }
            .navigationTitle(event == nil ? "Event Baru" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        Task {
                            await save()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var minimumCapacity: Int {
        max(event?.participantCount ?? 1, 1)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        capacity >= minimumCapacity &&
        endDate > startDate &&
        registrationDeadline <= startDate
    }

    private func save() async {
        let trimmedImageURL = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalImageURL = trimmedImageURL.isEmpty ? nil : trimmedImageURL

        if let event {
            await viewModel.updateEvent(
                event,
                title: title,
                description: description,
                imageURL: finalImageURL,
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
                imageURL: finalImageURL,
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

private struct ScheduleEventDetailView: View {
    @EnvironmentObject private var session: SessionManager
    @ObservedObject var viewModel: EventViewModel

    let event: EventModel
    let isMentor: Bool
    let onEdit: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                hero
                detailsCard
                actionCard
            }
            .padding(AppTheme.Spacing.lg)
            .padding(.bottom, 60)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Detail Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isMentor {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit", systemImage: "pencil", action: onEdit)
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            Task {
                                await viewModel.deleteEvent(event, session: session)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            if isMentor {
                await viewModel.loadParticipants(for: event)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ScheduleEventRow(event: event, isRegistered: viewModel.isRegistered(for: event), isMentor: isMentor)
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Informasi Event", actionTitle: nil)
            detailRow(icon: "calendar", title: "Mulai", value: event.startDate.formatted(date: .abbreviated, time: .shortened))
            detailRow(icon: "calendar.badge.clock", title: "Selesai", value: event.endDate.formatted(date: .abbreviated, time: .shortened))
            detailRow(icon: "hourglass", title: "Deadline", value: event.registrationDeadline.formatted(date: .abbreviated, time: .shortened))
            detailRow(icon: "person.2.fill", title: "Kapasitas", value: "\(event.participantCount)/\(event.capacity) peserta")
        }
        .cardStyle()
    }

    @ViewBuilder
    private var actionCard: some View {
        if isMentor {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(title: "Peserta", actionTitle: nil)
                if viewModel.eventParticipants.isEmpty {
                    Text("Belum ada peserta yang terdaftar.")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    ForEach(viewModel.eventParticipants) { participant in
                        HStack(spacing: AppTheme.Spacing.md) {
                            ProfileAvatarView(urlString: participant.user?.profileImageURL, size: 42)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(participant.user?.fullName ?? "Unknown User")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(participant.user?.email ?? participant.registration.userId)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            Button {
                                Task {
                                    await viewModel.removeParticipant(participant, from: event, session: session)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.error)
                            }
                        }
                    }
                }
            }
            .cardStyle()
        } else {
            VStack(spacing: AppTheme.Spacing.md) {
                if viewModel.isRegistered(for: event) {
                    Button {
                        Task {
                            await viewModel.cancelRegistration(for: event, session: session)
                        }
                    } label: {
                        Text("Batalkan Registrasi")
                    }
                    .secondaryButton()
                } else {
                    Button {
                        Task {
                            await viewModel.register(for: event, session: session)
                        }
                    } label: {
                        Text(event.isRegistrationOpen ? "Daftar Event" : "Registrasi Ditutup")
                    }
                    .primaryButton(isEnabled: event.isRegistrationOpen)
                    .disabled(!event.isRegistrationOpen)
                }
            }
            .cardStyle()
        }
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 32, height: 32)
                .background(AppTheme.primaryGlow)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
