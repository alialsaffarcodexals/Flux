import Foundation
import FirebaseFirestore

final class PortfolioRepository {
    static let shared = PortfolioRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var portfolioProjectsCollection: CollectionReference {
        manager.db.collection("portfolioProjects")
    }

    func createPortfolioProject(
        _ project: PortfolioProject,
        completion: @escaping (Result<PortfolioProject, Error>) -> Void
    ) {
        let document = portfolioProjectsCollection.document()
        do {
            try document.setData(from: project) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdProject = project
                createdProject.id = document.documentID
                completion(.success(createdProject))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchPortfolioProject(
        by id: String,
        completion: @escaping (Result<PortfolioProject, Error>) -> Void
    ) {
        portfolioProjectsCollection.document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(self.manager.missingSnapshotError()))
                return
            }

            guard snapshot.exists else {
                completion(.failure(self.manager.documentNotFoundError("PortfolioProject")))
                return
            }

            do {
                let project = try snapshot.data(as: PortfolioProject.self)
                completion(.success(project))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchPortfolioProjects(
        providerId: String,
        completion: @escaping (Result<[PortfolioProject], Error>) -> Void
    ) {
        portfolioProjectsCollection.whereField("providerId", isEqualTo: providerId)
            .getDocuments { snapshot, error in
                self.manager.decodeDocuments(snapshot, error: error, completion: completion)
            }
    }

    func updatePortfolioProject(
        _ project: PortfolioProject,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let id = project.id else {
            completion(.failure(manager.missingDocumentIdError("PortfolioProject")))
            return
        }

        do {
            try portfolioProjectsCollection.document(id).setData(from: project, merge: true) { error in
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

    func deletePortfolioProject(
        id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        portfolioProjectsCollection.document(id).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
}
