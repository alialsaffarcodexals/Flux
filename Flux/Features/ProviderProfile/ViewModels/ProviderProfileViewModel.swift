import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProviderProfileViewModel {
    
    // MARK: - Bindings
    var onError: ((String) -> Void)?
    // New binding to notify the VC when the switch is done
    var onSwitchToBuyer: ((User) -> Void)?
    
    // MARK: - Actions
    func didTapServiceSeekerProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 1. Switch back to Buyer Mode in Firestore
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "activeProfileMode": ProfileMode.buyerMode.rawValue
        ]) { [weak self] error in
            
            if let error = error {
                self?.onError?(error.localizedDescription)
                return
            }
            
            // 2. Fetch fresh user data to ensure the UI has the latest state
            FirestoreManager.shared.getUser(uid: uid) { result in
                switch result {
                case .success(let updatedUser):
                    // 3. Notify the View Controller to swap the screen
                    self?.onSwitchToBuyer?(updatedUser)
                    
                case .failure(let error):
                    self?.onError?("Failed to switch modes: \(error.localizedDescription)")
                }
            }
        }
    }
}
