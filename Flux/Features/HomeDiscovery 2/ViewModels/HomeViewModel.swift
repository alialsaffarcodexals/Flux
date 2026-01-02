import UIKit

// MARK: - Models
// Defined in Models/Company.swift


// 🔥 ADD THIS BACK: This fixes the "Cannot find FilterOptions" error
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

// MARK: - View Model
class HomeViewModel {
    
    // Hardcoded Categories - Simple text, No icons
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
    
    // 🔥 ADD THIS BACK: So the filter screen functions correctly
    func applyFilters(_ filters: FilterOptions) {
        var filtered = allCompanies
        filtered = filtered.filter { $0.price <= filters.maxPrice }
        if filters.minRating > 0 {
            filtered = filtered.filter { $0.rating >= filters.minRating }
        }
        
        switch filters.sortBy {
        case .relevance: break
        case .priceLowToHigh: filtered.sort { $0.price < $1.price }
        case .priceHighToLow: filtered.sort { $0.price > $1.price }
        case .rating: filtered.sort { $0.rating > $1.rating }
        case .newest: filtered.sort { $0.dateAdded > $1.dateAdded }
        }
        
        recommendedCompanies = filtered
    }
}
