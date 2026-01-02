import UIKit

class HomeViewModel {
    
    // Dependencies
    private let serviceRepo = ServiceRepository.shared
    private let userRepo = UserRepository.shared
    
    // Data Sources
    var recommendedProviders: [User] = []
    var displayedServices: [Service] = []
    var categories: [ServiceCategory] = []
    
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
        
        // 1. Fetch Providers (Recommended)
        group.enter()
        userRepo.fetchRecommendedProviders { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let providers):
                self?.recommendedProviders = providers
            case .failure(let error):
                print("❌ Error fetching providers: \(error.localizedDescription)")
            }
        }
        
        // 2. Fetch Services (Grid)
        group.enter()
        serviceRepo.fetchActiveServices { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let services):
                self?.allServices = services
                self?.displayedServices = services // Show all initially
            case .failure(let error):
                print("❌ Error fetching services: \(error.localizedDescription)")
            }
        }
        
        // 3. Fetch Categories
        group.enter()
        serviceRepo.fetchCategories(activeOnly: true) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let fetchedCategories):
                guard let self = self else { return }
                
                // Create the manual "All" category
                let allCategory = ServiceCategory(id: "ALL", name: "All", isActive: true)
                
                // Combine "All" + Fetched Categories
                self.categories = [allCategory] + fetchedCategories
                
            case .failure(let error):
                print("❌ Error fetching categories: \(error.localizedDescription)")
            }
        }
        
        // 4. Notify when ALL 3 requests are done
        group.notify(queue: .main) {
            completion()
        }
    }
    
    // MARK: - Logic
    
    func filterBy(category: String) {
        if category == "All" {
            displayedServices = allServices
        } else {
            // Case-insensitive filtering
            displayedServices = allServices.filter {
                $0.category.lowercased() == category.lowercased()
            }
        }
    }
    
    func getRandomColor() -> UIColor {
        return fluxPastelColors.randomElement() ?? .systemGray6
    }
}
