import Foundation
import FirebaseFirestore

// MARK: - Review

import Foundation
import FirebaseFirestore


struct Review: Identifiable, Codable {
    @DocumentID var id: String?

    var bookingId: String
    var serviceId: String
    var providerId: String
    var seekerId: String

    var rating: Int
    var comment: String

    var timestamp: Date

    // Custom Initializer (Fixes the "Extra Argument" error)
    init(bookingId: String, serviceId: String, providerId: String, seekerId: String, rating: Int, comment: String) {
        self.bookingId = bookingId
        self.serviceId = serviceId
        self.providerId = providerId
        self.seekerId = seekerId
        self.rating = rating
        self.comment = comment
        self.timestamp = Date()
    }
}
