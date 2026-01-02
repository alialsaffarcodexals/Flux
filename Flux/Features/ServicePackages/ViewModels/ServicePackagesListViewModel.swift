import Foundation
import Combine
import FirebaseAuth

class ServicePackagesListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var packages: [ServicePackage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let repository: ServicePackagesRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(repository: ServicePackagesRepositoryProtocol = FirestoreServicePackagesRepository.shared) {
        self.repository = repository
    }
    
    // MARK: - Methods
    
    func loadPackages() {
        guard let providerId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not logged in"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        repository.fetchPackagesForProvider(providerId: providerId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let fetchedPackages):
                    self?.packages = fetchedPackages
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deletePackage(_ package: ServicePackage) {
        self.isLoading = true
        repository.deletePackage(packageId: package.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.packages.removeAll { $0.id == package.id }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
