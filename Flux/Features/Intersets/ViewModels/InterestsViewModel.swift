import Foundation
import FirebaseAuth

class InterestsViewModel {
    
    // Callbacks
    var onCategoriesUpdated: (() -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSaveSuccess: (() -> Void)?
    
    // Data
    private(set) var categories: [ServiceCategory] = []
    private(set) var selectedInterestNames: Set<String> = []
    
    // Dependencies
    private let packagesRepo = FirestoreServicePackagesRepository.shared
    private let userRepo = UserRepository.shared
    
    init() {}
    
    func fetchCategories() {
        onLoading?(true)
        packagesRepo.fetchCategories { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)
                switch result {
                case .success(let fetchedCategories):
                    self?.categories = fetchedCategories
                    self?.onCategoriesUpdated?()
                    self?.loadUserInterests()
                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }
    
    private func loadUserInterests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        userRepo.getUser(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    if let interests = user.interests {
                        self?.selectedInterestNames = Set(interests)
                        self?.onCategoriesUpdated?() // Refresh UI
                    }
                case .failure(let error):
                    print("Error loading user interests: \(error.localizedDescription)")
                    // Non-critical, just log
                }
            }
        }
    }
    
    func toggleInterest(at index: Int) {
        guard index >= 0 && index < categories.count else { return }
        let categoryName = categories[index].name
        
        if selectedInterestNames.contains(categoryName) {
            selectedInterestNames.remove(categoryName)
        } else {
            selectedInterestNames.insert(categoryName)
        }
        
        onCategoriesUpdated?()
    }
    
    func isSelected(at index: Int) -> Bool {
        guard index >= 0 && index < categories.count else { return false }
        return selectedInterestNames.contains(categories[index].name)
    }
    
    func saveInterests() {
        guard let uid = Auth.auth().currentUser?.uid else {
            onError?("User not logged in.")
            return
        }
        
        onLoading?(true)
        let interestsArray = Array(selectedInterestNames)
        
        userRepo.updateUserField(uid: uid, field: "interests", value: interestsArray) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)
                switch result {
                case .success:
                    self?.onSaveSuccess?()
                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }
}
