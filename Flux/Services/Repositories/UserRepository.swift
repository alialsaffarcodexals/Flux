import Foundation
import FirebaseFirestore

final class UserRepository {
    static let shared = UserRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var usersCollection: CollectionReference {
        manager.db.collection("users")
    }

    func getUser(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        usersCollection.document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(self.manager.missingSnapshotError()))
                return
            }

            guard snapshot.exists else {
                completion(.failure(self.manager.documentNotFoundError("User")))
                return
            }

            do {
                let user = try snapshot.data(as: User.self)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updateUserField(uid: String, field: String, value: Any, completion: @escaping (Result<Void, Error>) -> Void) {
        usersCollection.document(uid).updateData([field: value]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
