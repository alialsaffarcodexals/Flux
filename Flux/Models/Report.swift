import Foundation
import FirebaseFirestore

struct Report: Identifiable, Codable {
    @DocumentID var id: String?
    
    var reporterId: String
    var reportedUserId: String
    
    var reason: String // e.g., "Toxic Behavior"
    var description: String
    var evidenceImageURL: String? // Screenshot
    
    var status: String // "Open", "Resolved"
    var timestamp: Date
}
