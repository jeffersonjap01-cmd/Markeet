import Foundation

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

struct ActivityAssignmentModel: Identifiable, Equatable {
    let assignmentId: String
    var id: String { assignmentId }
    var activityId: String
    var userId: String
    var completed: Bool
    var completedAt: Date?
    var assignedAt: Date
}

struct ScheduledActivity: Identifiable, Equatable {
    var id: String { activity.activityId }
    var activity: ActivityModel
    var assignment: ActivityAssignmentModel?
    var mentor: UserModel?

    var isCompleted: Bool {
        assignment?.completed == true
    }
}
