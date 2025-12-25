import Foundation
import FirebaseFirestore

// MARK: - Service (Session-only pricing)

struct Service: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String

    var title: String
    var description: String
    var category: String

    // Session-only pricing
    var sessionPrice: Double
    var currencyCode: String?      // Optional, e.g. "BHD"

    var coverImageURL: String

    var rating: Double?
    var reviewCount: Int?

    var isActive: Bool           // ✅ NEW
    var createdAt: Date
    var updatedAt: Date?         // ✅ NEW (optional)
}
