import Foundation
import FirebaseFirestore

// MARK: - PortfolioProject

struct PortfolioProject: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String

    var title: String
    var description: String
    var imageURLs: [String]

    var timestamp: Date
}
