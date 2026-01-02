import UIKit

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
    func fetchHomeData(completion: @escaping () -> Void) {
            let group = DispatchGroup()
            
            // 1. Fetch Recommended Providers (Top Section)
            group.enter()
            userRepo.fetchRecommendedProviders { [weak self] result in
                defer { group.leave() }
                if case .success(let providers) = result {
                    self?.recommendedProviders = providers
                }
            }
            
            // 2. Fetch Services AND THEN Fetch their Provider Names
            group.enter()
            serviceRepo.fetchActiveServices { [weak self] result in
                switch result {
                case .success(let services):
                    self?.allServices = services
                    self?.displayedServices = services
                    
                    // ✅ EXTRACT IDs
                    let providerIds = services.map { $0.providerId }
                    
                    // ✅ FETCH PROVIDER NAMES
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
    
    // MARK: - Logic
    

    func filterBy(category: String) {
        if category == "All" {
            // Reset to show everything
            displayedServices = allServices
        } else {
            // Filter by matching category name (Case Insensitive is safer)
            displayedServices = allServices.filter { service in
                return service.category.localizedCaseInsensitiveContains(category) ||
                       category.localizedCaseInsensitiveContains(service.category)
            }
        }
        
        print("🔍 Filtered by \(category): Found \(displayedServices.count) services")
    }
    
    func getRandomColor() -> UIColor {
        return fluxPastelColors.randomElement() ?? .systemGray6
    }
}
