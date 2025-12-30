import Foundation
import FirebaseFirestore

// MARK: - Review

struct Review: Identifiable, Codable {
    @DocumentID var id: String?

    var bookingId: String
    var serviceId: String
    var providerId: String
    var seekerId: String

    var rating: Int
    var comment: String

    var timestamp: Date
}
