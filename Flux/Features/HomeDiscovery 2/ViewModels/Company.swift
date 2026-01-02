//
//  Company.swift
//  Flux
//
//  Created by Guest User on 02/01/2026.
//


import UIKit

struct Company {
    var name: String
    var description: String
    var backgroundColor: UIColor
    var category: String
    var price: Double
    var rating: Double
    var dateAdded: Date
    var imageURL: String 
}

struct CategoryData {
    let name: String
    let color: UIColor
}

class HomeViewModel {
    // 1. Hardcoded Categories (Safe for demo)
    let categories: [CategoryData] = [
        CategoryData(name: "All", color: .systemGray6),
        CategoryData(name: "Cleaning", color: UIColor(red: 0.92, green: 0.98, blue: 0.92, alpha: 1.0)),
        CategoryData(name: "Lessons", color: UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1.0)),
        CategoryData(name: "Media", color: UIColor(red: 1.00, green: 0.95, blue: 0.90, alpha: 1.0)),
        CategoryData(name: "Courses", color: UIColor(red: 0.95, green: 0.92, blue: 1.00, alpha: 1.0))
    ]
    
    private var allCompanies: [Company] = []
    var recommendedCompanies: [Company] = []
    var selectedCategoryIndex: Int = 0
    let repo = HomeRepository()

    func fetchLiveServices(completion: @escaping () -> Void) {
        repo.fetchServices { result in
            switch result {
            case .success(let services):
                self.allCompanies = services
                self.recommendedCompanies = services
                completion()
            case .failure(let error):
                print("❌ Home Error: \(error.localizedDescription)")
                completion()
            }
        }
    }

    func filterBy(category: String) {
        if category == "All" {
            recommendedCompanies = allCompanies
        } else {
            recommendedCompanies = allCompanies.filter { $0.category == category }
        }
    }
}