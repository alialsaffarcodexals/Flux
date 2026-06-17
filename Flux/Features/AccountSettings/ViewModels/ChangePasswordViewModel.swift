import Foundation
import FirebaseAuth

class ChangePasswordViewModel {
    
    // MARK: - Properties
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?
    
    private let authManager = AuthManager.shared
    
    // MARK: - Actions
    
    func submit(currentPassword: String, newPassword: String, confirmPassword: String) {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            onError?("Please fill in all fields.")
            return
        }
        
        guard newPassword == confirmPassword else {
            onError?("Passwords do not match.")
            return
        }
        
        if newPassword == currentPassword {
            onError?("New password must be different from your current password.")
            return
        }
        
        guard newPassword.count >= 6 else {
            onError?("Password must be at least 6 characters.")
            return
        }
        
        onLoadingChanged?(true)
        
        // 1. Re-authenticate
        authManager.reauthenticate(password: currentPassword) { [weak self] success, error in
            guard let self = self else { return }
            
            if let error = error {
                self.onLoadingChanged?(false)
                self.onError?(error.localizedDescription)
                return
            }
            
            // 2. Update Password
            self.authManager.updatePassword(to: newPassword) { success, error in
                self.onLoadingChanged?(false)
                
                if let error = error {
                    self.onError?(error.localizedDescription)
                    return
                }
                
                self.handleSuccess()
            }
        }
    }
    
    private func handleSuccess() {
        // 3. Logout and Notify
        do {
            try authManager.signOut()
            onSuccess?()
        } catch {
            onError?("Password updated, but logout failed: \(error.localizedDescription)")
        }
    }
}
