import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case seeker = "Seeker"
    case provider = "Provider"
    case admin = "Admin"
}

enum ProfileMode: String, Codable {
    case buyerMode = "Buyer Mode"
    case sellerMode = "Seller Mode"
}

struct User: Identifiable, Codable {
    @DocumentID var id: String?

    var firstName: String
    var lastName: String
    var username: String
    var email: String
    var phoneNumber: String
    var profileImageURL: String?
    var location: String?

    var role: UserRole
    var joinedDate: Date
    var activeProfileMode: ProfileMode?

    var interests: [String]?

    // ✅ UPDATED: store favorite PROVIDER ids (not service ids)
    var favoriteProviderIds: [String]?

    var businessName: String?
    var bio: String?
    var isVerified: Bool?

    var name: String { "\(firstName) \(lastName)" }

    init(
        id: String? = nil,
        firstName: String,
        lastName: String,
        username: String,
        email: String,
        phoneNumber: String,
        role: UserRole = .seeker
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.phoneNumber = phoneNumber
        self.role = role
        self.joinedDate = Date()
        self.activeProfileMode = .buyerMode
    }
}
