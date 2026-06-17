import Foundation
import FirebaseFirestore

struct AvailabilitySlot: Codable, Identifiable {
    @DocumentID var id: String?
    let providerId: String
    let dayOfWeek: Int // 1 = Sunday, 7 = Saturday (Calendar.current.component(.weekday))
    let startTime: String // "HH:mm" 24-hour format
    let endTime: String   // "HH:mm" 24-hour format
    let isActive: Bool
    let validUntil: Date?
    
    enum SlotType: String, Codable {
        case available
        case blocked
    }
    
    let type: SlotType? // Optional for backward compatibility

    // Helper for Firestore mapping
    enum CodingKeys: String, CodingKey {
        case id
        case providerId
        case dayOfWeek
        case startTime
        case endTime
        case isActive
        case validUntil
        case type
    }
}
