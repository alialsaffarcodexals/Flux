import Foundation
import FirebaseFirestore

// MARK: - Skill

enum SkillStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
}

enum SkillLevel: String, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case expert = "Expert"
}

struct Skill: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String

    var name: String
    var level: SkillLevel?
    var description: String?

    var proofImageURL: String?

    var status: SkillStatus
    var adminFeedback: String?
}
