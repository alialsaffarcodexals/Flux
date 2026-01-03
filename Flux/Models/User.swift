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
    var phoneNumber: String?
    var seekerProfileImageURL: String?
    var providerProfileImageURL: String?
    var location: String?

    var role: UserRole
    var joinedDate: Date
    var activeProfileMode: ProfileMode?

    //  New Field: Tracks if the user has finished the Provider onboarding
    var hasCompletedProviderSetup: Bool?

    var interests: [String]?

    ///  Favorite PROVIDERS (Provider user IDs)
        var favoriteProviderIds: [String]?

    ///  Favorite SERVICES (Service IDs)
    var favoriteServiceIds: [String]?

    var businessName: String?
    var bio: String?
    var isVerified: Bool?
    // Account flags
    var isSuspended: Bool?
    var isBanned: Bool?
    var suspendedUntil: Date?
    // Reason provided by admin when suspending or banning
    var moderationReason: String?

    var name: String { "\(firstName) \(lastName)" }
    
    /// Helper computed property to get the profile image URL for a specific mode
    func profileImageURL(for mode: ProfileMode) -> String? {
        switch mode {
        case .buyerMode:
            return seekerProfileImageURL
        case .sellerMode:
            return providerProfileImageURL
        }
    }

    init(
        id: String? = nil,
        firstName: String,
        lastName: String,
        username: String,
        email: String,
        phoneNumber: String? = nil,
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
