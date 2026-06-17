import Foundation
import FirebaseFirestore

struct ServicePackage: Identifiable, Codable {
    let id: String
    let providerId: String
    var title: String
    var description: String
    var price: Double
    var categoryId: String
    var category: String // Keeps the name for display/denormalization
    var coverImageUrl: String?
    let createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    
    // Explicit init for creating new instances
    init(id: String = UUID().uuidString,
         providerId: String,
         title: String,
         description: String,
         price: Double,
         categoryId: String,
         category: String,
         coverImageUrl: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         isActive: Bool = true) {
        self.id = id
        self.providerId = providerId
        self.title = title
        self.description = description
        self.price = price
        self.categoryId = categoryId
        self.category = category
        self.coverImageUrl = coverImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
    
    // MARK: - Manual Mapping
    
    init?(id: String, data: [String: Any]) {
        guard let providerId = data["providerId"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let price = data["price"] as? Double,
              let category = data["category"] as? String else {
            return nil
        }
        
        self.id = id
        self.providerId = providerId
        self.title = title
        self.description = description
        self.price = price
        self.category = category
        // Fallback for legacy documents: use empty string or infer if possible
        self.categoryId = data["categoryId"] as? String ?? "" 
        self.coverImageUrl = data["coverImageUrl"] as? String
        self.isActive = data["isActive"] as? Bool ?? true
        
        if let createdTimestamp = data["createdAt"] as? Timestamp {
            self.createdAt = createdTimestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
        
        if let updatedTimestamp = data["updatedAt"] as? Timestamp {
            self.updatedAt = updatedTimestamp.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "providerId": providerId,
            "title": title,
            "description": description,
            "price": price,
            "categoryId": categoryId,
            "category": category,
            "coverImageUrl": coverImageUrl ?? "",
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isActive": isActive
        ]
    }
}
