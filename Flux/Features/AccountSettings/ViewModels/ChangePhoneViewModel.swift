import Foundation
import FirebaseAuth

class ChangePhoneViewModel {
    
    // MARK: - Properties
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?
    
    private let authManager = AuthManager.shared
    private let userRepository = UserRepository.shared
    
    // MARK: - Actions
    
    func submit(newPhone: String, password: String) {
        guard !newPhone.isEmpty, !password.isEmpty else {
            onError?("Please fill in all fields.")
            return
        }
        
        // Basic phone validation (customizable)
        guard newPhone.count >= 8 else {
            onError?("Please enter a valid phone number.")
            return
        }
        
        onLoadingChanged?(true)
        
        // 0. Check for No-Op (Same Phone)
        guard let uid = Auth.auth().currentUser?.uid else {
            self.onLoadingChanged?(false)
            self.onError?("User not found.")
            return
        }
        
        // Fetch current user data to compare phone number
        userRepository.getUser(uid: uid) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                if let currentPhone = user.phoneNumber, currentPhone == newPhone {
                    self.onLoadingChanged?(false)
                    self.onError?("This phone number is already your current number.")
                    return
                }
                
                // Proceed to Re-auth
                self.performReauthAndSubmit(uid: uid, newPhone: newPhone, password: password)
                
            case .failure(let error):
                self.onLoadingChanged?(false)
                self.onError?("Failed to verify current phone: \(error.localizedDescription)")
            }
        }
    }
    
    private func performReauthAndSubmit(uid: String, newPhone: String, password: String) {
        // 1. Re-authenticate
        authManager.reauthenticate(password: password) { [weak self] success, error in
            guard let self = self else { return }
            
            if let error = error {
                self.onLoadingChanged?(false)
                self.onError?(error.localizedDescription)
                return
            }
            
            // 2. Update Phone in Firestore (since Auth update requires OTP usually)
            if let uid = Auth.auth().currentUser?.uid {
                self.userRepository.updateUserField(uid: uid, field: "phoneNumber", value: newPhone) { result in
                    
                    self.onLoadingChanged?(false)
                    
                    switch result {
                    case .success:
                        self.handleSuccess()
                    case .failure(let error):
                        self.onError?("Failed to update phone number: \(error.localizedDescription)")
                    }
                }
            } else {
                self.onLoadingChanged?(false)
                self.onError?("User not found.")
            }
        }
    }
    
    private func handleSuccess() {
        // 3. Logout and Notify
        do {
            try authManager.signOut()
            onSuccess?()
        } catch {
            onError?("Phone updated, but logout failed: \(error.localizedDescription)")
        }
    }
}
