import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    
    var bookingId: String
    var serviceId: String
    var providerId: String
    var seekerId: String
    
    var rating: Int // 1 to 5
    var comment: String
    
    var timestamp: Date
}
