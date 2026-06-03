import Foundation

/// Mentor-created schedule activity stored in `activities`.
/// The activity owns high-level details and the list of assigned users, while
/// per-user completion is tracked separately in `activity_assignments`.
struct ActivityModel: Identifiable, Equatable {
    let activityId: String
    var id: String { activityId }
    var title: String
    var description: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var mentorId: String
    var assignedUserIds: [String]
    var createdAt: Date
    var updatedAt: Date
}

/// Per-user activity assignment document.
/// This keeps completion status independent for every assigned member.
struct ActivityAssignmentModel: Identifiable, Equatable {
    let assignmentId: String
    var id: String { assignmentId }
    var activityId: String
    var userId: String
    var completed: Bool
    var completedAt: Date?
    var assignedAt: Date
}

/// UI-friendly pairing of an activity with the current user's assignment.
/// Calendar dots and activity completion buttons are based on this combined view.
struct ScheduledActivity: Identifiable, Equatable {
    var id: String { activity.activityId }
    var activity: ActivityModel
    var assignment: ActivityAssignmentModel?
    var mentor: UserModel?

    var isCompleted: Bool {
        assignment?.completed == true
    }
}
