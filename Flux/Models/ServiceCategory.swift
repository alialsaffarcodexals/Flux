import Foundation
import FirebaseFirestore

struct ServiceCategory: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String // e.g., "Plumbing", "Coding"
    var iconURL: String? // Cloudinary URL
    var isActive: Bool // Admin can hide categories without deleting
}
