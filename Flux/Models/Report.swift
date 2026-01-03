import Foundation
import FirebaseFirestore

// MARK: - Report

struct Report: Identifiable, Codable {
    @DocumentID var id: String?

    var reporterId: String
    var reportedUserId: String

    var reason: String
    var description: String
    var evidenceImageURL: String?

    var status: String           // "Open", "Resolved"
    var timestamp: Date
    // Optional admin response stored when a report is reviewed
    var answer: String? = nil
}
