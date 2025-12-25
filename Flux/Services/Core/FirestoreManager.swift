/// File: FirestoreManager.swift.
/// Purpose: Shared Firestore access and reusable helpers.
/// Location: Services/FirestoreManager.swift.

import Foundation
import FirebaseFirestore

/// Class FirestoreManager.
/// Responsible for shared Firestore access and helper utilities.
class FirestoreManager {
    static let shared = FirestoreManager()
    let db: Firestore

    private init() {
        db = Firestore.firestore()
    }

    func missingDocumentIdError(_ entityName: String) -> Error {
        NSError(
            domain: "FirestoreManager",
            code: -1001,
            userInfo: [NSLocalizedDescriptionKey: "\(entityName) document ID is missing"]
        )
    }

    func documentNotFoundError(_ entityName: String) -> Error {
        NSError(
            domain: "FirestoreManager",
            code: -1002,
            userInfo: [NSLocalizedDescriptionKey: "\(entityName) not found"]
        )
    }

    func missingSnapshotError() -> Error {
        NSError(
            domain: "FirestoreManager",
            code: -1003,
            userInfo: [NSLocalizedDescriptionKey: "Missing snapshot data"]
        )
    }

    func decodeDocuments<T: Decodable>(
        _ snapshot: QuerySnapshot?,
        error: Error?,
        completion: @escaping (Result<[T], Error>) -> Void
    ) {
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let snapshot = snapshot else {
            completion(.failure(missingSnapshotError()))
            return
        }

        do {
            let items: [T] = try snapshot.documents.map { document in
                try document.data(as: T.self)
            }
            completion(.success(items))
        } catch {
            completion(.failure(error))
        }
    }
}
