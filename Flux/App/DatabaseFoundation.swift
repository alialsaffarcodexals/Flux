//
//  DatabaseFoundation.swift
//  Flux
//
//  Created by Mohammed Alnooh on 20/12/2025.
//

	
import Foundation
import FirebaseFirestore

class DatabaseFoundation {
    
    // Singleton Instance
    static let shared = DatabaseFoundation()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - 1. Get Single Document
    /// Fetches a single document by ID and decodes it into a Swift Struct.
    func fetchDocument<T: Decodable>(collection: String, docId: String, completion: @escaping (Result<T, Error>) -> Void) {
        let docRef = db.collection(collection).document(docId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                let notFoundError = NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found in \(collection)"])
                completion(.failure(notFoundError))
                return
            }
            
            do {
                let decodedData = try document.data(as: T.self)
                completion(.success(decodedData))
            } catch {
                print("Decoding Error: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - 2. Get Collection (With Filters)
    /// Fetches a list of documents. Optional: Provide filters (e.g., "price" > 20).
    func fetchCollection<T: Decodable>(collection: String,
                                       filters: [(field: String, value: Any)]? = nil,
                                       completion: @escaping (Result<[T], Error>) -> Void) {
        
        var query: Query = db.collection(collection)
        
        if let filters = filters {
            for filter in filters {
                query = query.whereField(filter.field, isEqualTo: filter.value)
            }
        }
        
        query.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            // Map documents to Structs
            let results = documents.compactMap { try? $0.data(as: T.self) }
            completion(.success(results))
        }
    }
    
    // MARK: - 3. Set Data (Create/Overwrite with specific ID)
    func setData<T: Encodable>(collection: String, docId: String, data: T, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection(collection).document(docId).setData(from: data) { error in
                if let error = error { completion(.failure(error)) }
                else { completion(.success(())) }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - 4. Add Data (Auto-ID)
    func addDocument<T: Encodable>(collection: String, data: T, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let ref = try db.collection(collection).addDocument(from: data) { error in
                if let error = error { completion(.failure(error)) }
            }
            // Return the new Auto-ID
            completion(.success(ref.documentID))
        } catch {
            completion(.failure(error))
        }
    }
}
