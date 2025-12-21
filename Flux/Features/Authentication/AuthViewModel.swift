/*
 File: AuthViewModel.swift
 Purpose: class AuthViewModel, func performLogin, func performSignUp, func getErrorMessage
 Location: Features/Authentication/AuthViewModel.swift
*/









import Foundation
import FirebaseAuth




/// Class AuthViewModel: Responsible for the lifecycle, state, and behavior related to AuthViewModel.
class AuthViewModel {
    
    

    


/// @Description: Performs the performLogin operation.
/// @Input: email: String?; password: String?; completion: @escaping (Bool; String?; User?
/// @Output: Void)
    func performLogin(email: String?, password: String?, completion: @escaping (Bool, String?, User?) -> Void) {
        
        guard let email = email, !email.isEmpty,
              let password = password, !password.isEmpty else {
            completion(false, "Please fill in all fields.", nil)
            return
        }

        
        AuthManager.shared.signIn(email: email, password: password) { [weak self] success, error in
            if let error = error {
                let friendlyMessage = self?.getErrorMessage(from: error) ?? "An unknown error occurred."
                completion(false, friendlyMessage, nil)
            } else {
                
                guard let uid = Auth.auth().currentUser?.uid else {
                    completion(false, "User ID not found.", nil)
                    return
                }
                
                FirestoreManager.shared.getUser(uid: uid) { result in
                    switch result {
                    case .success(let user):
                        
                        completion(true, nil, user)
                    case .failure(let error):
                        print("Error fetching user data: \(error.localizedDescription)")
                        
                        
                        completion(false, "Failed to retrieve user profile.", nil)
                    }
                }
            }
        }
    }



/// @Description: Performs the performSignUp operation.
/// @Input: name: String?; email: String?; password: String?; phone: String?; role: String; profileImage: Data?; completion: @escaping (Bool; String?
/// @Output: Void)
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
    


/// @Description: Performs the getErrorMessage operation.
/// @Input: from error: Error
/// @Output: String
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
