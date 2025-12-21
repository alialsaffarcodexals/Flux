/*
 File: AuthManager.swift
 Purpose: class AuthManager, func registerUser, func handleFinalCompletion, func saveUserToFirestore, func signIn, func signOut
 Location: Services/AuthManager.swift
*/









import Foundation
import FirebaseAuth
import FirebaseFirestore



/// Class AuthManager: Responsible for the lifecycle, state, and behavior related to AuthManager.
class AuthManager {
    
    static let shared = AuthManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {}
    


/// @Description: Performs the registerUser operation.
/// @Input: with userRequest: RegisterUserRequest; image: Data?; completion: @escaping (Bool; Error?
/// @Output: Void)
    public func registerUser(with userRequest: RegisterUserRequest, image: Data?, completion: @escaping (Bool, Error?) -> Void) {
        
        let email = userRequest.email
        let password = userRequest.password
        let name = userRequest.name
        let role = userRequest.role
        let phone = userRequest.phone
        
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
                        self?.saveUserToFirestore(uid: resultUser.uid, name: name, email: email, role: role, phone: phone, profileImageURL: downloadURL) { success in
                            self?.handleFinalCompletion(success: success, completion: completion)
                        }
                    case .failure(let error):
                        print("Warning: Image upload failed: \(error). Saving user without image.")
                        self?.saveUserToFirestore(uid: resultUser.uid, name: name, email: email, role: role, phone: phone, profileImageURL: nil) { success in
                            self?.handleFinalCompletion(success: success, completion: completion)
                        }
                    }
                }
            } else {
                self.saveUserToFirestore(uid: resultUser.uid, name: name, email: email, role: role, phone: phone, profileImageURL: nil) { success in
                    self.handleFinalCompletion(success: success, completion: completion)
                }
            }
        }
    }
    


/// @Description: Performs the handleFinalCompletion operation.
/// @Input: success: Bool; completion: @escaping (Bool; Error?
/// @Output: Void)
    private func handleFinalCompletion(success: Bool, completion: @escaping (Bool, Error?) -> Void) {
        if success {
            completion(true, nil)
        } else {
            let error = NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Account created but failed to save details."])
            completion(false, error)
        }
    }
    


/// @Description: Performs the saveUserToFirestore operation.
/// @Input: uid: String; name: String; email: String; role: String; phone: String; profileImageURL: String?; completion: @escaping (Bool
/// @Output: Void)
    private func saveUserToFirestore(uid: String, name: String, email: String, role: String, phone: String, profileImageURL: String?, completion: @escaping (Bool) -> Void) {
        
        var userData: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": email,
            "phone": phone,
            "role": role,
            "createdAt": Timestamp(date: Date())
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
    


/// @Description: Performs the signIn operation.
/// @Input: email: String; password: String; completion: @escaping (Bool; Error?
/// @Output: Void)
    public func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error)
                return
            }
            completion(true, nil)
        }
    }
    


/// @Description: Performs the signOut operation.
/// @Input: None
/// @Output: Void
    public func signOut() throws {
        try auth.signOut()
    }
}
