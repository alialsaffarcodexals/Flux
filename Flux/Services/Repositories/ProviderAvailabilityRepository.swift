import Foundation
import FirebaseFirestore

protocol ProviderAvailabilityRepository {
    func fetchAvailabilitySlots(providerId: String, completion: @escaping (Result<[AvailabilitySlot], Error>) -> Void)
    func fetchBlockedSlots(providerId: String, dateRange: ClosedRange<Date>, completion: @escaping (Result<[BlockedSlot], Error>) -> Void)
    func fetchProviderBookings(providerId: String, dateRange: ClosedRange<Date>, completion: @escaping (Result<[Booking], Error>) -> Void)
    
    func createAvailabilitySlot(_ slot: AvailabilitySlot, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteAvailabilitySlot(providerId: String, slotId: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    func createBlockedSlot(_ block: BlockedSlot, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteBlockedSlot(providerId: String, blockId: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    func fetchOneOffAvailabilitySlots(providerId: String, dateRange: ClosedRange<Date>, completion: @escaping (Result<[OneOffAvailabilitySlot], Error>) -> Void)
    func createOneOffAvailabilitySlot(_ slot: OneOffAvailabilitySlot, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteOneOffAvailabilitySlot(providerId: String, slotId: String, completion: @escaping (Result<Void, Error>) -> Void)
}

final class ProviderAvailabilityFirestoreRepository: ProviderAvailabilityRepository {
    
    static let shared = ProviderAvailabilityFirestoreRepository()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Collections
    // Adjust paths as per your Firestore structure
    private func availabilityCollection(providerId: String) -> CollectionReference {
        return db.collection("users").document(providerId).collection("availabilitySlots")
    }
    
    private func blockedSlotsCollection(providerId: String) -> CollectionReference {
        return db.collection("users").document(providerId).collection("blockedSlots")
    }
    
    private func bookingsCollection() -> CollectionReference {
        return db.collection("bookings")
    }
    
    private func oneOffAvailabilityCollection(providerId: String) -> CollectionReference {
        return db.collection("users").document(providerId).collection("oneOffAvailabilitySlots")
    }

    // MARK: - Availability Slots
    
    func fetchAvailabilitySlots(providerId: String, completion: @escaping (Result<[AvailabilitySlot], Error>) -> Void) {
        availabilityCollection(providerId: providerId).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            do {
                let slots = try documents.compactMap { try $0.data(as: AvailabilitySlot.self) }
                completion(.success(slots))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func createAvailabilitySlot(_ slot: AvailabilitySlot, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let _ = try availabilityCollection(providerId: slot.providerId).addDocument(from: slot) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteAvailabilitySlot(providerId: String, slotId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        availabilityCollection(providerId: providerId).document(slotId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Blocked Slots
    
    func fetchBlockedSlots(providerId: String, dateRange: ClosedRange<Date>, completion: @escaping (Result<[BlockedSlot], Error>) -> Void) {
        blockedSlotsCollection(providerId: providerId)
            .whereField("endTime", isGreaterThanOrEqualTo: dateRange.lowerBound)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                do {
                    var blocks = try documents.compactMap { try $0.data(as: BlockedSlot.self) }
                    // Client-side filter for startTime <= dateRange.upperBound
                    blocks = blocks.filter { $0.startTime <= dateRange.upperBound }
                    completion(.success(blocks))
                } catch {
                    completion(.failure(error))
                }
            }
    }
    
    func createBlockedSlot(_ block: BlockedSlot, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let _ = try blockedSlotsCollection(providerId: block.providerId).addDocument(from: block) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteBlockedSlot(providerId: String, blockId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        blockedSlotsCollection(providerId: providerId).document(blockId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Bookings
    
    func fetchProviderBookings(providerId: String, dateRange: ClosedRange<Date>, completion: @escaping (Result<[Booking], Error>) -> Void) {
        bookingsCollection()
            .whereField("providerId", isEqualTo: providerId)
            .whereField("scheduledAt", isGreaterThanOrEqualTo: dateRange.lowerBound)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                do {
                    var bookings = try documents.compactMap { try $0.data(as: Booking.self) }
                    // Client-side filter for upper bound
                    bookings = bookings.filter { $0.scheduledAt <= dateRange.upperBound }
                    completion(.success(bookings))
                } catch {
                    completion(.failure(error))
                }
            }
    }
    // MARK: - One-Off Availability Slots
    
    func fetchOneOffAvailabilitySlots(providerId: String, dateRange: ClosedRange<Date>, completion: @escaping (Result<[OneOffAvailabilitySlot], Error>) -> Void) {
        oneOffAvailabilityCollection(providerId: providerId)
            .whereField("endTime", isGreaterThanOrEqualTo: dateRange.lowerBound)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                do {
                    var slots = try documents.compactMap { try $0.data(as: OneOffAvailabilitySlot.self) }
                    // Client-side filter for startTime <= dateRange.upperBound
                    slots = slots.filter { $0.startTime <= dateRange.upperBound }
                    completion(.success(slots))
                } catch {
                    completion(.failure(error))
                }
            }
    }
    
    func createOneOffAvailabilitySlot(_ slot: OneOffAvailabilitySlot, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let _ = try oneOffAvailabilityCollection(providerId: slot.providerId).addDocument(from: slot) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteOneOffAvailabilitySlot(providerId: String, slotId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        oneOffAvailabilityCollection(providerId: providerId).document(slotId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
