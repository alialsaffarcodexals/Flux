import Foundation
import FirebaseFirestore

// MARK: - Booking

enum BookingStatus: String, Codable {
    case requested = "Requested"     // Seeker Pending / Provider Request
    case accepted  = "Accepted"      // Provider Accepted
    case inProgress = "InProgress"   // Seeker In progress (optional but recommended)
    case completed = "Completed"
    case rejected  = "Rejected"      // Provider Dropped/Rejected
    case canceled  = "Canceled"      // optional
    case pending = "Pending"
}


struct Booking: Identifiable, Codable {
    @DocumentID var id: String?
    
    var seekerId: String
    var providerId: String
    var serviceId: String
    var providerName: String
    // Snapshot of service details at booking time
    var serviceTitle: String
    var priceAtBooking: Double
    var currencyCode: String?
    var coverImageURLAtBooking: String?   // optional, useful for UI cards
    
    //  Single chosen slot only (no session duration)
    var scheduledAt: Date
    var providerImageURL: String?
    var note: String?
    var status: BookingStatus
    var acceptedAt: Date?
    var startedAt: Date?
    var completedAt: Date?
    var rejectedAt: Date?
    var createdAt: Date
    var isReviewed: Bool?
}
