import Foundation
import UIKit
import Combine
import FirebaseAuth

enum ServicePackageValidationError: LocalizedError, Equatable {
    case missingTitle
    case invalidPrice
    case missingCategory
    case missingDescription
    case missingImage
    
    var errorDescription: String? {
        switch self {
        case .missingTitle: return "Service title is required."
        case .invalidPrice: return "Price must be a valid number."
        case .missingCategory: return "Please select a category."
        case .missingDescription: return "Description is required."
        case .missingImage: return "Please select a cover image."
        }
    }
}

class ServicePackageEditorViewModel: ObservableObject {
    
    // MARK: - Inputs
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var priceString: String = ""
    @Published var categoryName: String = "" // For display
    @Published var selectedCategory: ServiceCategory?
    @Published var coverImageUrl: String?
    @Published var selectedImage: UIImage?
    
    // MARK: - Outputs
    @Published var categories: [ServiceCategory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var validationError: ServicePackageValidationError?
    @Published var shouldDismiss: Bool = false
    
    // MARK: - Private
    private let repository: ServicePackagesRepositoryProtocol
    private var existingPackage: ServicePackage?
    var isEditing: Bool { existingPackage != nil }
    private var cancellables = Set<AnyCancellable>()
    
    private let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f
    }()
    
    // MARK: - Init
    init(package: ServicePackage? = nil, repository: ServicePackagesRepositoryProtocol = FirestoreServicePackagesRepository.shared) {
        self.repository = repository
        self.existingPackage = package
        
        setupInitialState()
        fetchCategories()
    }
    
    private func setupInitialState() {
        if let package = existingPackage {
            self.title = package.title
            self.description = package.description
            self.priceString = priceFormatter.string(from: NSNumber(value: package.price)) ?? "\(package.price)"
            self.categoryName = package.category
            self.coverImageUrl = package.coverImageUrl
            // selectedCategory will be matched in fetchCategories
        }
    }
    
    // MARK: - data
    func fetchCategories() {
        repository.fetchCategories { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let categories):
                    self?.categories = categories
                    self?.reconcileSelectedCategory(with: categories)
                case .failure(let error):
                    print("Error fetching categories: \(error)")
                }
            }
        }
    }
    
    private func reconcileSelectedCategory(with categories: [ServiceCategory]) {
        guard let existing = existingPackage else { return }
        // Try match by ID first, then Name
        if let match = categories.first(where: { $0.id == existing.categoryId }) {
            self.selectedCategory = match
            self.categoryName = match.name
        } else if let matchByName = categories.first(where: { $0.name == existing.category }) {
            self.selectedCategory = matchByName
            self.categoryName = matchByName.name
        }
    }
    
    // MARK: - Validation
    func validate() -> Bool {
        validationError = nil
        errorMessage = nil
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = .missingTitle
            errorMessage = validationError?.localizedDescription
            return false
        }
        
        if parsePrice(priceString) == nil {
            validationError = .invalidPrice
            errorMessage = validationError?.localizedDescription
            return false
        }
        
        if selectedCategory == nil {
            validationError = .missingCategory
            errorMessage = validationError?.localizedDescription
            return false
        }
        
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = .missingDescription
            errorMessage = validationError?.localizedDescription
            return false
        }
        
        // Image: Must have new selectedImage OR existing remote URL
        let hasImage = selectedImage != nil || (coverImageUrl != nil && !coverImageUrl!.isEmpty)
        if !hasImage {
            validationError = .missingImage
            errorMessage = validationError?.localizedDescription
            return false
        }
        
        return true
    }
    
    private func parsePrice(_ input: String) -> Double? {
        // 1. Try generic formatter
        if let number = priceFormatter.number(from: input) {
            return number.doubleValue
        }
        
        // 2. Fallback: try replacing comma with dot manually (simple robustness)
        let dotString = input.replacingOccurrences(of: ",", with: ".")
        if let directDouble = Double(dotString) {
            return directDouble
        }
        
        return nil
    }
    
    // MARK: - Actions
    func save() {
        guard !isLoading else { return }
        guard let providerId = Auth.auth().currentUser?.uid else {
            errorMessage = "User session not found."
            return
        }
        
        guard validate() else { return }
        
        isLoading = true
        
        // Flow: Upload Image (if new) -> Save Firestore
        if let image = selectedImage {
            StorageManager.shared.uploadServiceCoverImage(image: image) { [weak self] result in
                switch result {
                case .success(let url):
                    self?.coverImageUrl = url
                    self?.executeFirestoreSave(providerId: providerId)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = "Image upload failed: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            executeFirestoreSave(providerId: providerId)
        }
    }
    
    private func executeFirestoreSave(providerId: String) {
        guard let price = parsePrice(priceString) else { return } // Already validated
        guard let category = selectedCategory else { return } // Already validated
        
        if isEditing, var package = existingPackage {
            // Updated fields
            package.title = title
            package.description = description
            package.price = price
            package.categoryId = category.id ?? ""
            package.category = category.name
            package.coverImageUrl = coverImageUrl
            package.updatedAt = Date()
            
            repository.updatePackage(package: package) { [weak self] result in
                self?.handleSaveResult(result)
            }
        } else {
            let newPackage = ServicePackage(
                providerId: providerId,
                title: title,
                description: description,
                price: price,
                categoryId: category.id ?? "",
                category: category.name,
                coverImageUrl: coverImageUrl
            )
            
            repository.createPackage(package: newPackage) { [weak self] result in
                self?.handleSaveResult(result)
            }
        }
    }
    
    private func handleSaveResult(_ result: Result<Void, Error>) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            switch result {
            case .success:
                self?.shouldDismiss = true
            case .failure(let error):
                self?.errorMessage = "Save failed: \(error.localizedDescription)"
            }
        }
    }
    
    func selectCategory(_ category: ServiceCategory) {
        self.selectedCategory = category
        self.categoryName = category.name
        // Clear related error if user fixes it
        if validationError == .missingCategory {
            validationError = nil
            errorMessage = nil
        }
    }
}
