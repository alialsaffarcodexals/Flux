import Foundation
import FirebaseFirestore

struct PortfolioProject: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String
    
    var title: String // e.g., "Recipe App"
    var description: String
    
    // Array of Cloudinary URLs (allows multiple images per project)
    var imageURLs: [String]
    
    var timestamp: Date
}
