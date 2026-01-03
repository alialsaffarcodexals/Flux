import UIKit
import FirebaseAuth

// MARK: - Models
// Defined in Models/Company.swift


//  ADD THIS BACK: This fixes the "Cannot find FilterOptions" error
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
    
    // Dependencies
    private let serviceRepo = ServiceRepository.shared
    private let userRepo = UserRepository.shared
    
    // Data Sources
    var recommendedProviders: [User] = []
    var displayedServices: [Service] = []
    var categories: [ServiceCategory] = []
    var providerNames: [String: String] = [:]
    
    // Data Cache (To store all services for local filtering)
    private var allServices: [Service] = []
    
    // UI Helpers
    var selectedCategoryIndex: Int = 0
    private let fluxPastelColors: [UIColor] = [
        UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1.0),
        UIColor(red: 0.92, green: 0.98, blue: 0.92, alpha: 1.0),
        UIColor(red: 1.00, green: 0.95, blue: 0.90, alpha: 1.0),
        UIColor(red: 0.95, green: 0.92, blue: 1.00, alpha: 1.0)
    ]

    // MARK: - Fetching Data
    private let packagesRepo = FirestoreServicePackagesRepository.shared

    func fetchHomeData(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        // 1. Fetch Recommended Providers (Based on Interests if User Logged In)
        group.enter()
        // Check if user is logged in
        if let uid = Auth.auth().currentUser?.uid {
            userRepo.getUser(uid: uid) { [weak self] result in
                switch result {
                case .success(let user):
                    if let interests = user.interests, !interests.isEmpty {
                        // Fetch based on interests
                        self?.fetchRecommendationsBasedOnInterests(interests: interests, group: group)
                    } else {
                        // Fallback (User has no interests)
                        self?.fetchDefaultRecommendations(group: group)
                    }
                case .failure:
                    // Fallback (Fetch failed)
                    self?.fetchDefaultRecommendations(group: group)
                }
            }
        } else {
            // Not logged in
            fetchDefaultRecommendations(group: group)
        }
        
        // 2. Fetch Services AND THEN Fetch their Provider Names
        group.enter()
        serviceRepo.fetchActiveServices { [weak self] result in
            switch result {
            case .success(let services):
                self?.allServices = services
                self?.displayedServices = services
                
                //  EXTRACT IDs
                let providerIds = services.map { $0.providerId }
                
                //  FETCH PROVIDER NAMES
                self?.userRepo.fetchUsers(byIds: providerIds) { userResult in
                    if case .success(let users) = userResult {
                        // Create the lookup dictionary
                        for user in users {
                            // Map ID to Business Name (or Name)
                            self?.providerNames[user.id ?? ""] = user.businessName ?? user.name
                        }
                    }
                    // Leave group ONLY after getting names
                    group.leave()
                }
                
            case .failure(let error):
                print("Error: \(error)")
                group.leave()
            }
        }
        
        // 3. Fetch Categories
        group.enter()
        serviceRepo.fetchCategories(activeOnly: true) { [weak self] result in
            defer { group.leave() }
            if case .success(let fetchedCategories) = result {
                let allCategory = ServiceCategory(id: "ALL", name: "All", isActive: true)
                self?.categories = [allCategory] + fetchedCategories
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    private func fetchDefaultRecommendations(group: DispatchGroup) {
        userRepo.fetchRecommendedProviders { [weak self] result in
            defer { group.leave() }
            if case .success(let providers) = result {
                self?.recommendedProviders = providers
            }
        }
    }
    
    private func fetchRecommendationsBasedOnInterests(interests: [String], group: DispatchGroup) {
        // 1. Fetch Packages matching interests
        packagesRepo.fetchPackagesByCategories(categories: interests) { [weak self] result in
            switch result {
            case .success(let packages):
                // 2. Extract Provider IDs
                let providerIds = Array(Set(packages.map { $0.providerId }))
                
                if providerIds.isEmpty {
                    // Fallback if no specific providers found for interests
                    self?.fetchDefaultRecommendations(group: group)
                    return
                }
                
                // 3. Fetch Provider Details
                self?.userRepo.fetchUsers(byIds: providerIds) { userResult in
                    defer { group.leave() }
                    if case .success(let providers) = userResult {
                        self?.recommendedProviders = providers
                    }
                }
                
            case .failure:
                self?.fetchDefaultRecommendations(group: group)
            }
        }
    }
    
    // MARK: - Logic
    
    var currentFilterOptions = FilterOptions()
    private var searchText: String = ""

    /// Applies new filters from the FilterViewController
    func applyFilters(_ options: FilterOptions) {
        self.currentFilterOptions = options
        refilter()
    }
    
    /// Updates service list based on search text
    func search(query: String) {
        self.searchText = query
        refilter()
    }

    /// Updates the selected category and refilters the list
    func filterBy(category: String) {
        // We just store the category selection logic implicitly via index or we can store the string.
        // But `selectedCategoryIndex` is already tracking the UI state.
        // The previous implementation was direct. Now we need to Combine it.
        // We will assume `selectedCategoryIndex` maps to `categories` array.
        // So we just call refilter(), which should read the current category.
        
        // Wait, the VC calls this with the name. Let's keep it simple.
        refilter(forceCategory: category)
    }
    
    /// Centralized filtering method
    private func refilter(forceCategory: String? = nil) {
        // 1. Determine Category
        let categoryName: String
        if let imposed = forceCategory {
            categoryName = imposed
        } else if categories.indices.contains(selectedCategoryIndex) {
            categoryName = categories[selectedCategoryIndex].name
        } else {
            categoryName = "All"
        }
        
        // 2. Start with all services
        var result = allServices
        
        // 3. Apply Category Filter
        if categoryName != "All" {
            result = result.filter { service in
                service.category.localizedCaseInsensitiveContains(categoryName) ||
                categoryName.localizedCaseInsensitiveContains(service.category)
            }
        }
        
        // 4. Apply Price Filter
        // Only if max price is less than max possible (200), otherwise show all
        if currentFilterOptions.maxPrice < 200 {
            result = result.filter { $0.sessionPrice <= currentFilterOptions.maxPrice }
        }
        
        // 5. Apply Rating Filter
        if currentFilterOptions.minRating > 0 {
            result = result.filter { ($0.rating ?? 0) >= currentFilterOptions.minRating }
        }
        
        // 6. Apply Search Text
        if !searchText.isEmpty {
            result = result.filter { service in
                return service.title.localizedCaseInsensitiveContains(searchText) ||
                       service.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 7. Apply Sorting
        switch currentFilterOptions.sortBy {
        case .priceLowToHigh:
            result.sort { $0.sessionPrice < $1.sessionPrice }
        case .priceHighToLow:
            result.sort { $0.sessionPrice > $1.sessionPrice }
        case .rating:
            result.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .relevance:
            // Default order (usually newest or shuffled)
            break
        }
        
        displayedServices = result
        print("Refiltered: \(result.count) services found (Category: \(categoryName), Query: \(searchText))")
    }
    
    func getRandomColor() -> UIColor {
        return fluxPastelColors.randomElement() ?? .systemGray6
    }
}
