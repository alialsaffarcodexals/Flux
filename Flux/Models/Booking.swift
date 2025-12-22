import Foundation
import FirebaseFirestore

enum BookingStatus: String, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case completed = "Completed"
    case canceled = "Canceled"
    case rejected = "Rejected"
}

struct Booking: Identifiable, Codable {
    @DocumentID var id: String?
    
    var seekerId: String  // The Client
    var providerId: String // The Freelancer
    var serviceId: String // The specific Gig booked
    
    // Snapshot of key details (in case the Service is deleted later)
    var serviceTitle: String
    var priceAtBooking: Double
    
    var scheduledDate: Date
    var note: String? // "I need this done by Tuesday..."
    
    var status: BookingStatus
    var createdAt: Date
}
