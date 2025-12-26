import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?

    /// 2-person chat (Seeker <-> Provider)
    var participantIds: [String]          // [seekerId, providerId]
    var seekerId: String
    var providerId: String

    /// Optional: link the chat to a service/booking context
    var serviceId: String?
    var bookingId: String?

    /// For the "Direct" list UI
    var lastMessageText: String?
    var lastMessageSenderId: String?
    var lastMessageAt: Date?

    /// Simple unread tracking per user (uid -> count)
    var unreadCount: [String: Int]?

    var createdAt: Date
    var updatedAt: Date
}
