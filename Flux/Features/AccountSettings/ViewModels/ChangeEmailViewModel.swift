import Foundation
import FirebaseAuth

class ChangeEmailViewModel {
    
    // MARK: - Properties
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?
    
    private let authManager = AuthManager.shared
    private let userRepository = UserRepository.shared
    
    // MARK: - Actions
    
    func submit(newEmail: String, password: String) {
        guard !newEmail.isEmpty, !password.isEmpty else {
            onError?("Please fill in all fields.")
            return
        }
        
        guard isValidEmail(newEmail) else {
            onError?("Please enter a valid email address.")
            return
        }
        
        if let currentEmail = Auth.auth().currentUser?.email, currentEmail == newEmail {
            onError?("This email is already your current email.")
            return
        }
        
        onLoadingChanged?(true)
        
        // 1. Re-authenticate
        authManager.reauthenticate(password: password) { [weak self] success, error in
            guard let self = self else { return }
            
            if let error = error {
                self.onLoadingChanged?(false)
                self.onError?(error.localizedDescription)
                return
            }
            
            // 2. Update Email in Auth
            self.authManager.updateEmail(to: newEmail) { success, error in
                if let error = error {
                    self.onLoadingChanged?(false)
                    self.onError?(error.localizedDescription)
                    return
                }
                
                // 3. Update Email in Firestore (optional but recommended)
                if let uid = Auth.auth().currentUser?.uid {
                    self.userRepository.updateUserField(uid: uid, field: "email", value: newEmail) { result in
                        self.onLoadingChanged?(false)
                        switch result {
                        case .success:
                            self.handleSuccess()
                        case .failure(let error):
                            // Even if Firestore fails, Auth is updated. We could show a warning or just proceed.
                            // For strict consistency, we might want to rollback, but let's proceed for now.
                            print("Warning: Firestore email update failed: \(error)")
                            self.handleSuccess()
                        }
                    }
                } else {
                    self.onLoadingChanged?(false)
                    self.handleSuccess()
                }
            }
        }
    }
    
    private func handleSuccess() {
        // 4. Logout and Notify
        do {
            try authManager.signOut()
            onSuccess?()
        } catch {
            onError?("Email updated, but logout failed: \(error.localizedDescription)")
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
