import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable {
    case notification = "Notification"
    case activity = "Activity"
}

struct Notification: Identifiable, Codable {

    @DocumentID var id: String?

    var title: String
    var message: String
    var type: NotificationType

    var fromUserId: String?
    var fromName: String
    var toUserId: String

    var createdAt: Date
    var isRead: Bool

    init(
        id: String? = nil,
        title: String,
        message: String,
        type: NotificationType,
        fromUserId: String? = nil,
        fromName: String,
        toUserId: String,
        createdAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.fromUserId = fromUserId
        self.fromName = fromName
        self.toUserId = toUserId
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
