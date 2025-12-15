import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthManager {
    
    static let shared = AuthManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {}
    
    public func registerUser(with userRequest: RegisterUserRequest, completion: @escaping (Bool, Error?) -> Void) {
        
        let email = userRequest.email
        let password = userRequest.password
        let name = userRequest.name
        let role = userRequest.role // "Provider" or "Seeker"
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let resultUser = result?.user else {
                completion(false, nil)
                return
            }
            
            self.saveUserToFirestore(uid: resultUser.uid, name: name, email: email, role: role) { success in
                if success {
                    completion(true, nil)
                } else {
                    let error = NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account created but failed to save details."])
                    completion(false, error)
                }
            }
        }
    }
    
    // --- 2. Login Function ---
    public func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error)
                return
            }
            completion(true, nil)
        }
    }
    
    // --- 3. Save User Data (Helper) ---
    private func saveUserToFirestore(uid: String, name: String, email: String, role: String, completion: @escaping (Bool) -> Void) {
        let userData: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": email,
            "role": role,
            "createdAt": Timestamp(date: Date())
        ]
        
        // اسم الكولكشن في فيربيس سيكون "users"
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // --- 4. Sign Out ---
    public func signOut() throws {
        try auth.signOut()
    }
}
