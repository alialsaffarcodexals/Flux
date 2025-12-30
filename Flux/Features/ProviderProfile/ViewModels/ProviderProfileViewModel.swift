import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProviderProfileViewModel {
    
    // MARK: - Bindings
    // MARK: - Bindings
    var onError: ((String) -> Void)?
    var onSwitchToBuyer: ((User) -> Void)?
    var onUserDataUpdated: ((User) -> Void)? // New Binding
    var onSkillsUpdated: (([Skill]) -> Void)?
    var onLoading: ((Bool) -> Void)?
    
    // MARK: - Fetch Data
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        onLoading?(true)
        
        UserRepository.shared.getUser(uid: uid) { [weak self] result in
            
            // Note: We don't hide loading here because we might fetch skills right after or in parallel.
            // But if this is standalone, we should.
            // It's safer to just hide it here, and if fetchSkills is called, it triggers loading again.
            self?.onLoading?(false)
            
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
        
        onLoading?(true)
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "activeProfileMode": ProfileMode.buyerMode.rawValue
        ]) { [weak self] error in
            
            self?.onLoading?(false)
            
            if let error = error {
                self?.onError?(error.localizedDescription)
                return
            }
            
            self?.onLoading?(true) // Fetching user again
            
            UserRepository.shared.getUser(uid: uid) { result in
                
                self?.onLoading?(false)
                
                switch result {
                case .success(let updatedUser):
                    self?.onSwitchToBuyer?(updatedUser)
                case .failure(let error):
                    self?.onError?("Failed to switch modes: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchSkills(providerId: String) {
        // This might be called in parallel with fetchUserProfile
        // We'll trust the VC to handle multiple onLoading calls or just let it flicker if needed. 
        // But better: ActivityIndicator logic in VC handles multiple calls if we used a counter, but our extension is simple bool check.
        // Simple approach: show on start, hide on end.
        
        onLoading?(true)
        
        SkillRepository.shared.fetchSkills(for: providerId) { [weak self] result in
            
            self?.onLoading?(false)
            
            switch result {
            case .success(let skills):
                self?.onSkillsUpdated?(skills)
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
}
