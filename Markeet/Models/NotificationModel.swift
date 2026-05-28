import Foundation

enum NotificationType: String, Codable {
    case message
    case assignment
    case recommendation
    case event
    case report
}

struct NotificationModel: Identifiable, Equatable {
    let notificationId: String
    var id: String { notificationId }
    var recipientId: String
    var title: String
    var body: String
    var type: NotificationType
    var read: Bool
    var createdAt: Date
}
