import Foundation
import FirebaseFirestore

protocol ServicePackagesRepositoryProtocol {
    func createPackage(package: ServicePackage, completion: @escaping (Result<Void, Error>) -> Void)
    func updatePackage(package: ServicePackage, completion: @escaping (Result<Void, Error>) -> Void)
    func deletePackage(packageId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func fetchPackagesForProvider(providerId: String, completion: @escaping (Result<[ServicePackage], Error>) -> Void)
    // Stub for future seeker feed
    func fetchPackagesForFeed(limit: Int, lastSnapshot: Any?, completion: @escaping (Result<[ServicePackage], Error>) -> Void)
    func fetchCategories(completion: @escaping (Result<[ServiceCategory], Error>) -> Void)
}

class FirestoreServicePackagesRepository: ServicePackagesRepositoryProtocol {
    
    static let shared = FirestoreServicePackagesRepository()
    private let db = Firestore.firestore()
    private let collection = "servicePackages"
    
    private init() {}
    
    func createPackage(package: ServicePackage, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = package.toDictionary()
        db.collection(collection).document(package.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updatePackage(package: ServicePackage, completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure updated timestamp is set
        var updatedPackage = package
        updatedPackage.updatedAt = Date()
        
        let data = updatedPackage.toDictionary()
        
        db.collection(collection).document(updatedPackage.id).setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deletePackage(packageId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collection).document(packageId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchPackagesForProvider(providerId: String, completion: @escaping (Result<[ServicePackage], Error>) -> Void) {
        db.collection(collection)
            .whereField("providerId", isEqualTo: providerId)
            // Removed .order(by:) to avoid composite index requirement
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let packages = documents.compactMap { document -> ServicePackage? in
                    return ServicePackage(id: document.documentID, data: document.data())
                }
                
                // Client-side sorting
                let sortedPackages = packages.sorted { $0.createdAt > $1.createdAt }
                
                completion(.success(sortedPackages))
            }
    }
    
    func fetchCategories(completion: @escaping (Result<[ServiceCategory], Error>) -> Void) {
        db.collection("serviceCategories")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let categories = snapshot?.documents.compactMap { document -> ServiceCategory? in
                    let data = document.data()
                    guard let name = data["name"] as? String else { return nil }
                    let iconURL = data["iconURL"] as? String
                    let isActive = data["isActive"] as? Bool ?? true
                    return ServiceCategory(id: document.documentID, name: name, iconURL: iconURL, isActive: isActive)
                } ?? []

                let activeCategories = categories.filter { $0.isActive }
                let sortedCategories = activeCategories.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                completion(.success(sortedCategories))
            }
    }
    
    func fetchPackagesForFeed(limit: Int, lastSnapshot: Any? = nil, completion: @escaping (Result<[ServicePackage], Error>) -> Void) {
        var query = db.collection(collection)
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            
        if let lastSnapshot = lastSnapshot as? DocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let packages = documents.compactMap { document -> ServicePackage? in
                return ServicePackage(id: document.documentID, data: document.data())
            }
            
            completion(.success(packages))
        }
    }
}
