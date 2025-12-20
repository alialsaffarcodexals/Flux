import Foundation
import FirebaseAuth


class AuthViewModel {
    
    func performLogin(email: String?, password: String?, completion: @escaping (Bool, String?) -> Void) {
        
        guard let email = email, !email.isEmpty,
              let password = password, !password.isEmpty else {
            completion(false, "Please fill in all fields.")
            return
        }

        AuthManager.shared.signIn(email: email, password: password) { [weak self] success, error in
            if let error = error {
                let friendlyMessage = self?.getErrorMessage(from: error) ?? "An unknown error occurred."
                completion(false, friendlyMessage)
            } else {
                completion(true, nil)
            }
        }
    }

    func performSignUp(name: String?, email: String?, password: String?, phone: String?, role: String, profileImage: Data?, completion: @escaping (Bool, String?) -> Void) {

        guard let name = name, !name.isEmpty,
              let email = email, !email.isEmpty,
              let password = password, !password.isEmpty,
              let phone = phone, !phone.isEmpty else {
            completion(false, "Please fill all fields")
            return
        }
        
        let request = RegisterUserRequest(name: name, email: email, password: password, role: role, phone: phone)
        
        AuthManager.shared.registerUser(with: request, image: profileImage) { [weak self] success, error in
            if let error = error {
                let friendlyMessage = self?.getErrorMessage(from: error) ?? "Sign up failed."
                completion(false, friendlyMessage)
            } else {
                completion(true, nil)
            }
        }
    }
    
    private func getErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
                
                print("🔴 Firebase Error Code: \(nsError.code)")
                
                guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
                    return error.localizedDescription
                }

                switch errorCode {
                case .invalidEmail:
                    return "The email address is badly formatted."
                    
                case .userNotFound:
                    return "Account not found. Please sign up."
                    
                case .wrongPassword:
                    return "Incorrect password. Please try again."
                    
                case .invalidCredential:
                    return "Invalid email or password."
                    
                case .networkError:
                    return "Network error. Please check your connection."
                    
                case .emailAlreadyInUse:
                    return "This email is already in use."
                    
                case .weakPassword:
                    return "The password is too weak."
                    
                default:
                    print("⚠️ Unhandled Error Code: \(nsError.code)")
                    return "Authentication failed. (Error: \(nsError.code))"
                }
    }
}
