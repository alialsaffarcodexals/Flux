import Foundation
import FirebaseAuth

class AuthViewModel {
    
    // MARK: - Login
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

    // MARK: - Sign Up (Updated)
    // ✅ تم التحديث لاستقبال الاسم الأول، الأخير، واسم المستخدم
    func performSignUp(firstName: String?, lastName: String?, username: String?, email: String?, password: String?, phone: String?, role: String, profileImage: Data?, completion: @escaping (Bool, String?, User?) -> Void) {

        // ✅ التحقق من جميع الحقول الجديدة
        guard let firstName = firstName, !firstName.isEmpty,
              let lastName = lastName, !lastName.isEmpty,
              let username = username, !username.isEmpty,
              let email = email, !email.isEmpty,
              let password = password, !password.isEmpty,
              let phone = phone, !phone.isEmpty else {
            completion(false, "Please fill all fields", nil)
            return
        }
        
        // ✅ استدعاء AuthManager بالبيانات الصحيحة (هنا كان سبب الخطأ)
        AuthManager.shared.registerUser(firstName: firstName, lastName: lastName, username: username, email: email, password: password, phone: phone, image: profileImage) { [weak self] success, error in
            
            if let error = error {
                let friendlyMessage = self?.getErrorMessage(from: error) ?? "Sign up failed."
                completion(false, friendlyMessage, nil)
            } else {
                // جلب بيانات المستخدم بعد النجاح
                guard let uid = Auth.auth().currentUser?.uid else {
                    completion(false, "User created but ID missing.", nil)
                    return
                }
                
                FirestoreManager.shared.getUser(uid: uid) { result in
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
