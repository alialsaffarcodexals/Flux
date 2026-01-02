import Foundation
import FirebaseFirestore

struct AvailabilitySlot: Codable, Identifiable {
    @DocumentID var id: String?
    let providerId: String
    let dayOfWeek: Int // 1 = Sunday, 7 = Saturday (Calendar.current.component(.weekday))
    let startTime: String // "HH:mm" 24-hour format
    let endTime: String   // "HH:mm" 24-hour format
    let isActive: Bool

    // Helper for Firestore mapping
    enum CodingKeys: String, CodingKey {
        case id
        case providerId
        case dayOfWeek
        case startTime
        case endTime
        case isActive
    }
}
