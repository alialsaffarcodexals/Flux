//
//  HomeRepository 2.swift
//  Flux
//
//  Created by Guest User on 02/01/2026.
//


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
        db.collection("services").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let companies = snapshot?.documents.compactMap { doc -> Company? in
                let data = doc.data()
                let randomColor = self.fluxPastelColors.randomElement() ?? .systemGray6

                return Company(
                    name: data["title"] as? String ?? "No Title",
                    description: data["description"] as? String ?? "",
                    backgroundColor: randomColor,
                    category: data["category"] as? String ?? "All",
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