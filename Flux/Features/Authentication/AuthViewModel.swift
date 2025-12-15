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
    
        func performSignUp(name: String?, email: String?, password: String?, phone: String?, role: String, profileImage: Data?, completion: @escaping (Bool, String?) -> Void) {

            guard let name = name, !name.isEmpty,
                  let email = email, !email.isEmpty,
                  let password = password, !password.isEmpty,
                  let phone = phone, !phone.isEmpty else {
                completion(false, "Please fill all fields")
                return
            }
            
            if let imageData = profileImage {
                let fileName = "\(UUID().uuidString).jpg"
                StorageManager.shared.uploadProfilePicture(with: imageData, fileName: fileName) { [weak self] result in
                    switch result {
                    case .success(let downloadURL):
                        self?.registerUser(name: name, email: email, password: password, phone: phone, role: role, imageURL: downloadURL, completion: completion)
                        
                    case .failure(let error):
                        completion(false, "Image Upload Failed: \(error.localizedDescription)")
                    }
                }
            } else {
                registerUser(name: name, email: email, password: password, phone: phone, role: role, imageURL: nil, completion: completion)
            }
        }
        
        private func registerUser(name: String, email: String, password: String, phone: String, role: String, imageURL: String?, completion: @escaping (Bool, String?) -> Void) {
            
           
        }
}
