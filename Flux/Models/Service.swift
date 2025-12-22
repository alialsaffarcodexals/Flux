import Foundation
import FirebaseFirestore

enum PricingUnit: String, Codable, CaseIterable {
    case hour = "Hour"
    case day = "Day"
    case week = "Week"
    case session = "Session"
}

struct Service: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String // Links to the User who created this
    
    // MARK: - Service Details
    var title: String // e.g., "UI/UX Design"
    var description: String
    var category: String // e.g., "Design", "Cleaning"
    
    // MARK: - Pricing
    var price: Double // e.g., 100
    var pricingUnit: PricingUnit // e.g., .session
    
    // MARK: - Media
    var coverImageURL: String // Main display image
    
    // MARK: - Metrics (For Sorting/Ranking)
    var rating: Double? // Average rating (e.g., 4.8)
    var reviewCount: Int?
    
    var createdAt: Date
}
