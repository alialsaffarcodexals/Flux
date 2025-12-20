import Foundation
import FirebaseFirestore
import Combine

class HomeViewModel {
    
    // MARK: - Published Properties (These update UI automatically)
    @Published var allServices: [Service] = []
    @Published var recommendedServices: [Service] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Fetch Services from Firebase
    func fetchServices() {
        isLoading = true
        
        Firestore.firestore().collection("services").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                self?.allServices = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Service.self)
                } ?? []
            }
        }
    }
    
    // MARK: - Fetch Featured Services
    func fetchRecommendations() {
        Firestore.firestore().collection("services")
            .whereField("isFeatured", isEqualTo: true)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.recommendedServices = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: Service.self)
                    } ?? []
                }
            }
    }
}
