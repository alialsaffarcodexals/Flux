import Foundation
import FirebaseFirestore

final class ReviewRepository {
    static let shared = ReviewRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var reviewsCollection: CollectionReference {
        manager.db.collection("reviews")
    }

    func createReview(
        _ review: Review,
        completion: @escaping (Result<Review, Error>) -> Void
    ) {
        let document = reviewsCollection.document()
        do {
            try document.setData(from: review) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdReview = review
                createdReview.id = document.documentID
                completion(.success(createdReview))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchReview(
        by id: String,
        completion: @escaping (Result<Review, Error>) -> Void
    ) {
        reviewsCollection.document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(self.manager.missingSnapshotError()))
                return
            }

            guard snapshot.exists else {
                completion(.failure(self.manager.documentNotFoundError("Review")))
                return
            }

            do {
                let review = try snapshot.data(as: Review.self)
                completion(.success(review))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchReviews(
        completion: @escaping (Result<[Review], Error>) -> Void
    ) {
        reviewsCollection.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func updateReview(
        _ review: Review,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let id = review.id else {
            completion(.failure(manager.missingDocumentIdError("Review")))
            return
        }

        do {
            try reviewsCollection.document(id).setData(from: review, merge: true) { error in
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

    func deleteReview(
        id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        reviewsCollection.document(id).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    func fetchReviewsForService(
        serviceId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    ) {
        reviewsCollection.whereField("serviceId", isEqualTo: serviceId)
            .getDocuments { snapshot, error in
                self.manager.decodeDocuments(snapshot, error: error, completion: completion)
            }
    }

    func fetchReviewsForProvider(
        providerId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    ) {
        reviewsCollection.whereField("providerId", isEqualTo: providerId)
            .getDocuments { snapshot, error in
                self.manager.decodeDocuments(snapshot, error: error, completion: completion)
            }
    }
}
