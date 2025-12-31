import Foundation
import FirebaseAuth
import FirebaseFirestore

class SeekerProfileViewModel {
    
    // Bindings
    var onUserDataUpdated: ((User) -> Void)?
    var onError: ((String) -> Void)?
    var onNavigateToProviderSetup: (() -> Void)? // Trigger for new providers
    var onLoading: ((Bool) -> Void)?
    
    private var currentUser: User?

    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        onLoading?(true)
        
        UserRepository.shared.getUser(uid: uid) { [weak self] result in
            
            // Ensure loading is hidden
            defer { self?.onLoading?(false) }
            
            switch result {
            case .success(let user):
                self?.currentUser = user
                self?.onUserDataUpdated?(user)
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Switch Logic
    func didTapServiceProviderProfile() {
        guard let user = currentUser else { return }
        
        // 1. If user is ONLY a Seeker, they need to Upgrade (Go to Intro/Setup)
        if user.role == .seeker {
            self.onNavigateToProviderSetup?()
        }
        // 2. If user is ALREADY a Provider/Admin, just switch modes
        else {
            switchProfileMode(to: .sellerMode)
        }
    }
    
    private func switchProfileMode(to mode: ProfileMode) {
        guard let uid = currentUser?.id else { return }
        
        onLoading?(true)
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "activeProfileMode": mode.rawValue
        ]) { [weak self] error in
            
             // Ensure loading is hidden (unless we navigate immediately, but safe to hide)
             defer { self?.onLoading?(false) }
             
            if let error = error {
                self?.onError?(error.localizedDescription)
            } else {
                // Fetch fresh user data to ensure AppNavigator has the latest state
                UserRepository.shared.getUser(uid: uid) { result in
                    switch result {
                    case .success(let updatedUser):
                        DispatchQueue.main.async {
                            // ✅ UPDATE: Navigate to Tab 4 (Provider Profile)
                            // Provider Tabs: [Home, Requests, Manage, Chat, Profile] -> Index 4
                            AppNavigator.shared.navigate(user: updatedUser, destinationTab: 4)
                        }
                    case .failure:
                        self?.onError?("Failed to switch modes.")
                    }
                }
            }
        }
    }
}
