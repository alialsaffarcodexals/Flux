import Foundation
import FirebaseFirestore

final class ServiceRepository {
    static let shared = ServiceRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var servicesCollection: CollectionReference {
        manager.db.collection("services")
    }

    private var serviceCategoriesCollection: CollectionReference {
        manager.db.collection("serviceCategories")
    }

    // MARK: - ServiceCategory CRUD

    func createServiceCategory(
        _ category: ServiceCategory,
        completion: @escaping (Result<ServiceCategory, Error>) -> Void
    ) {
        let document = serviceCategoriesCollection.document()
        do {
            try document.setData(from: category) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdCategory = category
                createdCategory.id = document.documentID
                completion(.success(createdCategory))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchServiceCategory(
        by id: String,
        completion: @escaping (Result<ServiceCategory, Error>) -> Void
    ) {
        serviceCategoriesCollection.document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(self.manager.missingSnapshotError()))
                return
            }

            guard snapshot.exists else {
                completion(.failure(self.manager.documentNotFoundError("ServiceCategory")))
                return
            }

            do {
                let category = try snapshot.data(as: ServiceCategory.self)
                completion(.success(category))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchServiceCategories(
        completion: @escaping (Result<[ServiceCategory], Error>) -> Void
    ) {
        serviceCategoriesCollection.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func updateServiceCategory(
        _ category: ServiceCategory,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let id = category.id else {
            completion(.failure(manager.missingDocumentIdError("ServiceCategory")))
            return
        }

        do {
            try serviceCategoriesCollection.document(id).setData(from: category, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func deleteServiceCategory(
        id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        serviceCategoriesCollection.document(id).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    func fetchCategories(
        activeOnly: Bool,
        completion: @escaping (Result<[ServiceCategory], Error>) -> Void
    ) {
        let query: Query = activeOnly
            ? serviceCategoriesCollection.whereField("isActive", isEqualTo: true)
            : serviceCategoriesCollection

        query.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    // MARK: - Service CRUD

    func createService(
        _ service: Service,
        completion: @escaping (Result<Service, Error>) -> Void
    ) {
        let document = servicesCollection.document()
        do {
            try document.setData(from: service) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdService = service
                createdService.id = document.documentID
                completion(.success(createdService))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchService(
        by id: String,
        completion: @escaping (Result<Service, Error>) -> Void
    ) {
        servicesCollection.document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(self.manager.missingSnapshotError()))
                return
            }

            guard snapshot.exists else {
                completion(.failure(self.manager.documentNotFoundError("Service")))
                return
            }

            do {
                let service = try snapshot.data(as: Service.self)
                completion(.success(service))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchServices(
        completion: @escaping (Result<[Service], Error>) -> Void
    ) {
        servicesCollection.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func updateService(
        _ service: Service,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let id = service.id else {
            completion(.failure(manager.missingDocumentIdError("Service")))
            return
        }

        do {
            try servicesCollection.document(id).setData(from: service, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func deleteService(
        id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        servicesCollection.document(id).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    func fetchServicesByProvider(
        providerId: String,
        completion: @escaping (Result<[Service], Error>) -> Void
    ) {
        servicesCollection.whereField("providerId", isEqualTo: providerId)
            .getDocuments { snapshot, error in
                self.manager.decodeDocuments(snapshot, error: error, completion: completion)
            }
    }

    func fetchActiveServices(
        completion: @escaping (Result<[Service], Error>) -> Void
    ) {
        servicesCollection.whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                self.manager.decodeDocuments(snapshot, error: error, completion: completion)
            }
    }
}
