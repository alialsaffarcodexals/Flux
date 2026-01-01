import Foundation
import FirebaseFirestore

final class BookingRepository {
    static let shared = BookingRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var bookingsCollection: CollectionReference {
        manager.db.collection("bookings")
    }

    func createBooking(
        _ booking: Booking,
        completion: @escaping (Result<Booking, Error>) -> Void
    ) {
        let document = bookingsCollection.document()
        do {
            try document.setData(from: booking) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdBooking = booking
                createdBooking.id = document.documentID
                completion(.success(createdBooking))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchBooking(
        by id: String,
        completion: @escaping (Result<Booking, Error>) -> Void
    ) {
        bookingsCollection.document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(self.manager.missingSnapshotError()))
                return
            }

            guard snapshot.exists else {
                completion(.failure(self.manager.documentNotFoundError("Booking")))
                return
            }

            do {
                let booking = try snapshot.data(as: Booking.self)
                completion(.success(booking))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchBookings(
        completion: @escaping (Result<[Booking], Error>) -> Void
    ) {
        bookingsCollection.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func updateBooking(
        _ booking: Booking,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let id = booking.id else {
            completion(.failure(manager.missingDocumentIdError("Booking")))
            return
        }

        do {
            try bookingsCollection.document(id).setData(from: booking, merge: true) { error in
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

    func deleteBooking(
        id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        bookingsCollection.document(id).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    func fetchBookingsForSeeker(
        seekerId: String,
        status: BookingStatus?,
        completion: @escaping (Result<[Booking], Error>) -> Void
    ) {
        var query: Query = bookingsCollection.whereField("seekerId", isEqualTo: seekerId)
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        query.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func fetchBookingsForProvider(
        providerId: String,
        status: BookingStatus?,
        completion: @escaping (Result<[Booking], Error>) -> Void
    ) {
        var query: Query = bookingsCollection.whereField("providerId", isEqualTo: providerId)
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        query.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func updateBookingStatus(
        bookingId: String,
        newStatus: BookingStatus,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var updates: [String: Any] = ["status": newStatus.rawValue]
        let now = Date()

        switch newStatus {
        case .accepted:
            updates["acceptedAt"] = now
        case .inProgress:
            updates["startedAt"] = now
        case .completed:
            updates["completedAt"] = now
        case .rejected:
            updates["rejectedAt"] = now
        case .requested, .canceled, .pending:
            break
        }

        bookingsCollection.document(bookingId).updateData(updates) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    func fetchBookingsForProviderInRange(
        providerId: String,
        startAt: Date,
        endAt: Date,
        completion: @escaping (Result<[Booking], Error>) -> Void
    ) {
        bookingsCollection.whereField("providerId", isEqualTo: providerId)
            .whereField("scheduledAt", isGreaterThanOrEqualTo: startAt)
            .whereField("scheduledAt", isLessThanOrEqualTo: endAt)
            .getDocuments { snapshot, error in
                self.manager.decodeDocuments(snapshot, error: error, completion: completion)
            }
    }
    func markAsReviewed(bookingId: String, completion: @escaping (Result<Void, Error>) -> Void) {
            // ERROR CHECK: Is your collection named "bookings" or "Bookings"?
            // It must match your Firestore exactly (lowercase 'b').
            manager.db.collection("bookings").document(bookingId).updateData(["isReviewed": true]) { error in
                if let error = error {
                    print("❌ Error updating booking: \(error)")
                    completion(.failure(error))
                } else {
                    print("✅ Successfully marked booking as reviewed in database")
                    completion(.success(()))
                }
            }
        }
}
