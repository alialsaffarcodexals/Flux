import Foundation
import FirebaseFirestore

struct OneOffAvailabilitySlot: Codable, Identifiable {
    @DocumentID var id: String?
    let providerId: String
    let startTime: Date
    let endTime: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case providerId
        case startTime
        case endTime
        case createdAt
    }
}
