import Foundation
import FirebaseFirestore

// MARK: - Skill

enum SkillStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
}

struct Skill: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String

    var name: String
    var description: String?

    var proofImageURL: String?

    var status: SkillStatus
    var adminFeedback: String?
}
