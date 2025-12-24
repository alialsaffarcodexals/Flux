/// File: FirestoreManager.swift.
/// Purpose: Class FirestoreManager, func getUser.
/// Location: Services/FirestoreManager.swift.

import Foundation
import FirebaseFirestore

/// Class FirestoreManager.
/// Responsible for the lifecycle, state, and behavior related to FirestoreManager.
class FirestoreManager {
    static let shared = FirestoreManager() 
    private let db = Firestore.firestore()
    
    private init() {} 
    

    /// Performs the getUser operation.
    /// - Parameters:
    ///   - uid: String representing the user ID.
    ///   - completion: Completion handler with Result<User, Error>.
    /// - Returns: Void.
    func getUser(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            do {
                // Use Codable to map directly to the new User model.
                if let user = try snapshot?.data(as: User.self) {
                    completion(.success(user))
                } else {
                    completion(.failure(NSError(domain: "Flux", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    
}
