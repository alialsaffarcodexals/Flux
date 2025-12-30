import Foundation
import FirebaseAuth

/// ViewModel responsible for handling authentication-related operations.
class AuthViewModel {
    
    // MARK: - Properties
    
    /// Callback to notify view controllers of loading state changes.
    var onLoading: ((Bool) -> Void)?

    // MARK: - Login
    
    /// Performs login with given email and password.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    ///   - completion: Completion handler with success flag, optional error message, and optional User object.
    func performLogin(email: String?, password: String?, completion: @escaping (Bool, String?, User?) -> Void) {
        
        guard let email = email, !email.isEmpty,
              let password = password, !password.isEmpty else {
            completion(false, "Please fill in all fields.", nil)
            return
        }

        self.onLoading?(true)
        
        AuthManager.shared.signIn(email: email, password: password) { [weak self] success, error in
            
            // Ensure loading is hidden on return
            defer { self?.onLoading?(false) }
            
            if let error = error {
                let friendlyMessage = self?.getErrorMessage(from: error) ?? "An unknown error occurred."
                completion(false, friendlyMessage, nil)
            } else {
                guard let uid = Auth.auth().currentUser?.uid else {
                    completion(false, "User ID not found.", nil)
                    return
                }
                
                UserRepository.shared.getUser(uid: uid) { result in
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

    // MARK: - Sign Up (Updated)
    /// Updated to accept first name, last name, and username.
    ///
    /// Performs sign up with additional user details.
    /// - Parameters:
    ///   - firstName: The user's first name.
    ///   - lastName: The user's last name.
    ///   - username: The user's username.
    ///   - email: The user's email address.
    ///   - password: The user's password.
    ///   - phone: The user's phone number.
    ///   - role: The user's role.
    ///   - profileImage: The user's profile image data.
    ///   - completion: Completion handler with success flag, optional error message, and optional User object.
    func performSignUp(firstName: String?, lastName: String?, username: String?, email: String?, password: String?, phone: String?, role: String, profileImage: Data?, completion: @escaping (Bool, String?, User?) -> Void) {

        // Validate all new fields.
        guard let firstName = firstName, !firstName.isEmpty,
              let lastName = lastName, !lastName.isEmpty,
              let username = username, !username.isEmpty,
              let email = email, !email.isEmpty,
              let password = password, !password.isEmpty,
              let phone = phone, !phone.isEmpty else {
            completion(false, "Please fill all fields", nil)
            return
        }
        
        self.onLoading?(true)
        
        // Call AuthManager with correct data (this was the cause of the previous error).
        AuthManager.shared.registerUser(firstName: firstName, lastName: lastName, username: username, email: email, password: password, phone: phone, image: profileImage) { [weak self] success, error in
            
            // Ensure loading is hidden on return
            defer { self?.onLoading?(false) }
            
            if let error = error {
                let friendlyMessage = self?.getErrorMessage(from: error) ?? "Sign up failed."
                completion(false, friendlyMessage, nil)
            } else {
                // Fetch user data after successful registration.
                guard let uid = Auth.auth().currentUser?.uid else {
                    completion(false, "User created but ID missing.", nil)
                    return
                }
                
                UserRepository.shared.getUser(uid: uid) { result in
                    switch result {
                    case .success(let user):
                        completion(true, nil, user)
                    case .failure(let error):
                        print("⚠️ User created but fetch failed: \(error)")
                        completion(false, "Failed to load user profile.", nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// Returns a user-friendly error message based on the Firebase error.
    /// - Parameter error: The error returned from Firebase.
    /// - Returns: A string describing the error in a friendly manner.
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
            return "Authentication failed. (Error: \(nsError.code))"
        }
    }
}
