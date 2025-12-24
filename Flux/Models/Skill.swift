import Foundation
import FirebaseFirestore

enum SkillStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
}

struct Skill: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String
    
    var name: String // e.g., "SwiftUI"
    var description: String?
    
    // Cloudinary URL for the certificate/proof
    var proofImageURL: String?
    
    var status: SkillStatus
    var adminFeedback: String? // Populated if status == .rejected
}
