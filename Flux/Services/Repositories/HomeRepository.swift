import Foundation
import FirebaseFirestore

class HomeRepository {
    private let db = Firestore.firestore()
    
    let fluxPastelColors: [UIColor] = [
        UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1.0),
        UIColor(red: 0.92, green: 0.98, blue: 0.92, alpha: 1.0),
        UIColor(red: 1.00, green: 0.95, blue: 0.90, alpha: 1.0),
        UIColor(red: 0.95, green: 0.92, blue: 1.00, alpha: 1.0),
        UIColor(red: 1.00, green: 0.92, blue: 0.95, alpha: 1.0)
    ]

    func fetchServices(completion: @escaping (Result<[Company], Error>) -> Void) {
        print("DEBUG: Fetching services from Firebase...")
        db.collection("services").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let companies = snapshot?.documents.compactMap { doc -> Company? in
                let data = doc.data()
                
                // TRACKING: This prints the Title of every document in your database
                print("DATABASE ITEM FOUND: \(data["title"] ?? "No Title Found")")

                let randomColor = self.fluxPastelColors.randomElement() ?? .systemGray6

                return Company(
                    id: doc.documentID,
                    providerId: data["providerId"] as? String ?? "",
                    name: data["title"] as? String ?? "No Title",
                    description: data["description"] as? String ?? "",
                    backgroundColor: randomColor,
                    category: data["category"] as? String ?? "General",
                    price: data["sessionPrice"] as? Double ?? 0.0,
                    rating: data["rating"] as? Double ?? 0.0,
                    dateAdded: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    imageURL: data["coverImageURL"] as? String ?? ""
                )
            } ?? []
            completion(.success(companies))
        }
    }
}
