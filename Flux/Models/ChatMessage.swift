import Foundation
import FirebaseFirestore

enum MessageType: String, Codable {
    case text = "text"
    case image = "image" // optional for future
}

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?

    var conversationId: String
    var senderId: String
    var receiverId: String

    var type: MessageType
    var text: String?            // used when type == .text
    var imageURL: String?        // used when type == .image (optional)

    var sentAt: Date

    /// Basic read receipt (optional)
    var isRead: Bool?
    var readAt: Date?
}
