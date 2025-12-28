import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthManager {
    
    static let shared = AuthManager()
    
    // Define core variables (solution for Error 3, 4, 5).
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // Update the method signature to accept first name, last name, and username.
    public func registerUser(firstName: String, lastName: String, username: String, email: String, password: String, phone: String, image: Data?, completion: @escaping (Bool, Error?) -> Void) {
        
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
            
            if let imageData = image {
                let fileName = "\(resultUser.uid)_profile.jpg"
                StorageManager.shared.uploadProfilePicture(with: imageData, fileName: fileName) { [weak self] result in
                    switch result {
                    case .success(let downloadURL):
                        // Pass new user data for saving.
                        self?.saveUserToFirestore(uid: resultUser.uid, firstName: firstName, lastName: lastName, username: username, email: email, phone: phone, profileImageURL: downloadURL) { success in
                            self?.handleFinalCompletion(success: success, completion: completion)
                        }
                    case .failure(let error):
                        print("Warning image upload: \(error)")
                        self?.saveUserToFirestore(uid: resultUser.uid, firstName: firstName, lastName: lastName, username: username, email: email, phone: phone, profileImageURL: nil) { success in
                            self?.handleFinalCompletion(success: success, completion: completion)
                        }
                    }
                }
            } else {
                self.saveUserToFirestore(uid: resultUser.uid, firstName: firstName, lastName: lastName, username: username, email: email, phone: phone, profileImageURL: nil) { success in
                    self.handleFinalCompletion(success: success, completion: completion)
                }
            }
        }
    }

    /// Internal save method.

    private func saveUserToFirestore(uid: String, firstName: String, lastName: String, username: String, email: String, phone: String, profileImageURL: String?, completion: @escaping (Bool) -> Void) {
        
        // Store new fields in the dictionary.
        var userData: [String: Any] = [
            "uid": uid,
            "id": uid,
            "firstName": firstName,
            "lastName": lastName,
            "username": username,
            "email": email,
            "phoneNumber": phone,
            "role": UserRole.seeker.rawValue,
            "activeProfileMode": ProfileMode.buyerMode.rawValue,
            "location": "Bahrain", // 📍 Default location for all new users
            "joinedDate": Timestamp(date: Date())
        ]
        
        if let imageURL = profileImageURL {
            userData["profileImageURL"] = imageURL
        }
        
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Define the helper function (solution for Error 2).
    private func handleFinalCompletion(success: Bool, completion: @escaping (Bool, Error?) -> Void) {
        if success {
            completion(true, nil)
        } else {
            let error = NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account created but failed to save details."])
            completion(false, error)
        }
    }
    
    // MARK: - Sign In & Sign Out
    
    public func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error)
                return
            }
            completion(true, nil)
        }
    }
    
    public func signOut() throws {
        try auth.signOut()
    }

    
}
