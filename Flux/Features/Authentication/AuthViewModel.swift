import Foundation

class AuthViewModel {
    
    func performLogin(email: String?, password: String?, completion: @escaping (Bool, String?) -> Void) {
        
        guard let email = email, !email.isEmpty,
              let password = password, !password.isEmpty else {
            completion(false, "Please fill in all fields.")
            return
        }
        
        AuthManager.shared.signIn(email: email, password: password) { success, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    func performSignUp(name: String?, email: String?, password: String?, role: String, completion: @escaping (Bool, String?) -> Void) {
        
        guard let name = name, !name.isEmpty,
              let email = email, !email.isEmpty,
              let password = password, !password.isEmpty else {
            completion(false, "Please fill all fields")
            return
        }
        
        let request = RegisterUserRequest(name: name, email: email, password: password, role: role)
        
        AuthManager.shared.registerUser(with: request) { success, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
}
