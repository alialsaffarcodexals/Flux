import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProviderProfileViewModel {
    
    // MARK: - Bindings
    var onError: ((String) -> Void)?
    var onSwitchToBuyer: ((User) -> Void)?
    var onUserDataUpdated: ((User) -> Void)? // New Binding
    
    // MARK: - Fetch Data
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        UserRepository.shared.getUser(uid: uid) { [weak self] result in
            switch result {
            case .success(let user):
                self?.onUserDataUpdated?(user)
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Actions
    func didTapServiceSeekerProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "activeProfileMode": ProfileMode.buyerMode.rawValue
        ]) { [weak self] error in
            
            if let error = error {
                self?.onError?(error.localizedDescription)
                return
            }
            
            UserRepository.shared.getUser(uid: uid) { result in
                switch result {
                case .success(let updatedUser):
                    self?.onSwitchToBuyer?(updatedUser)
                case .failure(let error):
                    self?.onError?("Failed to switch modes: \(error.localizedDescription)")
                }
            }
        }
    }
}
