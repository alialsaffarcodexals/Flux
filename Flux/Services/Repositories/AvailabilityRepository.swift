import Foundation
import FirebaseFirestore

final class AvailabilityRepository {
    static let shared = AvailabilityRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var providerAvailabilityCollection: CollectionReference {
        manager.db.collection("providerAvailability")
    }

    private var availabilityBlocksCollection: CollectionReference {
        manager.db.collection("availabilityBlocks")
    }

    func upsertProviderAvailability(
        providerId: String,
        serviceId: String,
        availableDays: [Date],
        availableTimes: [String],
        completion: @escaping (Result<ProviderAvailability, Error>) -> Void
    ) {
        let availability = ProviderAvailability(
            id: nil,
            providerId: providerId,
            serviceId: serviceId,
            availableDays: availableDays,
            availableTimes: availableTimes,
            updatedAt: Date()
        )

        providerAvailabilityCollection
            .whereField("providerId", isEqualTo: providerId)
            .whereField("serviceId", isEqualTo: serviceId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(self.manager.missingSnapshotError()))
                    return
                }

                if let document = snapshot.documents.first {
                    do {
                        try document.reference.setData(from: availability, merge: true) { error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            var updatedAvailability = availability
                            updatedAvailability.id = document.documentID
                            completion(.success(updatedAvailability))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    let document = self.providerAvailabilityCollection.document()
                    do {
                        try document.setData(from: availability) { error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            var createdAvailability = availability
                            createdAvailability.id = document.documentID
                            completion(.success(createdAvailability))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
    }

    func fetchProviderAvailability(
        providerId: String,
        serviceId: String,
        completion: @escaping (Result<ProviderAvailability, Error>) -> Void
    ) {
        providerAvailabilityCollection
            .whereField("providerId", isEqualTo: providerId)
            .whereField("serviceId", isEqualTo: serviceId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(self.manager.missingSnapshotError()))
                    return
                }

                guard let document = snapshot.documents.first else {
                    completion(.failure(self.manager.documentNotFoundError("ProviderAvailability")))
                    return
                }

                do {
                    let availability = try document.data(as: ProviderAvailability.self)
                    completion(.success(availability))
                } catch {
                    completion(.failure(error))
                }
            }
    }

    func createAvailabilityBlock(
        providerId: String,
        startAt: Date,
        endAt: Date,
        reason: String?,
        completion: @escaping (Result<AvailabilityBlock, Error>) -> Void
    ) {
        let block = AvailabilityBlock(
            id: nil,
            providerId: providerId,
            startAt: startAt,
            endAt: endAt,
            reason: reason,
            createdAt: Date()
        )
        let document = availabilityBlocksCollection.document()

        do {
            try document.setData(from: block) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdBlock = block
                createdBlock.id = document.documentID
                completion(.success(createdBlock))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchAvailabilityBlocks(
        providerId: String,
        startAt: Date,
        endAt: Date,
        completion: @escaping (Result<[AvailabilityBlock], Error>) -> Void
    ) {
        availabilityBlocksCollection.whereField("providerId", isEqualTo: providerId)
            .whereField("startAt", isGreaterThanOrEqualTo: startAt)
            .whereField("startAt", isLessThanOrEqualTo: endAt)
            .getDocuments { snapshot, error in
                self.manager.decodeDocuments(snapshot, error: error, completion: completion)
            }
    }

    func deleteAvailabilityBlock(
        blockId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        availabilityBlocksCollection.document(blockId).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
}
