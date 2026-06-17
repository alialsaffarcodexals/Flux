import Foundation
import FirebaseFirestore

// MARK: - ProviderAvailability (NEW)

struct ProviderAvailability: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String
    var serviceId: String

    // Store day-only dates (midnight) for calendar UI
    var availableDays: [Date]

    // Store times in a stable format for parsing (recommended: "HH:mm")
    // Example: ["09:00", "16:00", "21:00"]
    var availableTimes: [String]

    var updatedAt: Date
}
