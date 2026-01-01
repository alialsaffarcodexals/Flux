//
//  HomeViewModel.swift
//  Flux
//

import UIKit

// MARK: - Company Model
struct Company {
    var name: String
    var description: String
    var backgroundColor: UIColor
    var category: String
    var price: Double
    var rating: Double
    var dateAdded: Date
}

// MARK: - Filter Options Model
struct FilterOptions {
    var maxPrice: Double = 200
    var minRating: Double = 0
    var sortBy: SortOption = .relevance
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case priceLowToHigh = "Price: Low to High"
        case priceHighToLow = "Price: High to Low"
        case rating = "Highest Rated"
        case newest = "Newest First"
    }
}

// MARK: - Home View Model
class HomeViewModel {
    
    // All companies (original data)
    private var allCompanies: [Company] = []
    
    // Filtered companies (what we show on screen)
    var recommendedCompanies: [Company] = []
    
    // MARK: - Load Dummy Data
    func loadDummyData() {
        
        allCompanies = [
            Company(
                name: "CleanMax",
                description: "Home Cleaning Service",
                backgroundColor: .systemGreen,
                category: "Services",
                price: 50.0,
                rating: 4.8,
                dateAdded: Date()
            ),
            Company(
                name: "Max J.",
                description: "Video Editor",
                backgroundColor: .systemBlue.withAlphaComponent(0.5),
                category: "Media",
                price: 75.0,
                rating: 4.5,
                dateAdded: Date().addingTimeInterval(-86400)
            ),
            Company(
                name: "Sam A.",
                description: "Social Media Manager",
                backgroundColor: .systemOrange,
                category: "Services",
                price: 100.0,
                rating: 4.9,
                dateAdded: Date().addingTimeInterval(-172800)
            ),
            Company(
                name: "TutorPro",
                description: "Math & Science Lessons",
                backgroundColor: .systemPurple,
                category: "Lessons",
                price: 25.0,
                rating: 5.0,
                dateAdded: Date().addingTimeInterval(-259200)
            ),
            Company(
                name: "CodeAcademy",
                description: "Programming Courses",
                backgroundColor: .systemTeal,
                category: "Courses",
                price: 150.0,
                rating: 4.7,
                dateAdded: Date().addingTimeInterval(-345600)
            ),
            Company(
                name: "PhotoStudio",
                description: "Photography & Editing",
                backgroundColor: .systemPink,
                category: "Media",
                price: 80.0,
                rating: 4.3,
                dateAdded: Date().addingTimeInterval(-432000)
            )
        ]
        
        // Show all companies initially
        recommendedCompanies = allCompanies
    }
    
    // MARK: - Apply Filters
    func applyFilters(_ filters: FilterOptions) {
        
        // Start with all companies
        var filtered = allCompanies
        
        // Filter by max price
        filtered = filtered.filter { $0.price <= filters.maxPrice }
        
        // Filter by minimum rating
        if filters.minRating > 0 {
            filtered = filtered.filter { $0.rating >= filters.minRating }
        }
        
        // Apply sorting
        switch filters.sortBy {
        case .relevance:
            break
        case .priceLowToHigh:
            filtered.sort { $0.price < $1.price }
        case .priceHighToLow:
            filtered.sort { $0.price > $1.price }
        case .rating:
            filtered.sort { $0.rating > $1.rating }
        case .newest:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        }
        
        // Update displayed data
        recommendedCompanies = filtered
    }
}
