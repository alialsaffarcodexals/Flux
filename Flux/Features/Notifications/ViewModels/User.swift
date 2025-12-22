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
    
    // ✅ 1. الحقول الجديدة
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
    var favoriteServiceIds: [String]?
    
    var businessName: String?
    var bio: String?
    var isVerified: Bool?
    
    // ✅ 2. خاصية محسوبة لدمج الاسم (عشان الكود القديم ما يخرب)
    var name: String {
        return "\(firstName) \(lastName)"
    }
    
    // Initializer
    init(id: String? = nil, firstName: String, lastName: String, username: String, email: String, phoneNumber: String, role: UserRole = .seeker) {
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
