import Foundation
import FirebaseFirestore

// MARK: - ServiceCategory

struct ServiceCategory: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var iconURL: String?
    var isActive: Bool
}
