import Foundation
import FirebaseFirestore

final class ReportRepository {
    static let shared = ReportRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var reportsCollection: CollectionReference {
        manager.db.collection("reports")
    }

    func createReport(
        reporterId: String,
        reportedUserId: String,
        reason: String,
        description: String,
        evidenceImageURL: String?,
        status: String = "Open",
        completion: @escaping (Result<Report, Error>) -> Void
    ) {
        let report = Report(
            id: nil,
            reporterId: reporterId,
            reportedUserId: reportedUserId,
            reason: reason,
            description: description,
            evidenceImageURL: evidenceImageURL,
            status: status,
            timestamp: Date()
        )

        let document = reportsCollection.document()
        do {
            try document.setData(from: report) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdReport = report
                createdReport.id = document.documentID
                completion(.success(createdReport))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchReport(
        by id: String,
        completion: @escaping (Result<Report, Error>) -> Void
    ) {
        reportsCollection.document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(self.manager.missingSnapshotError()))
                return
            }

            guard snapshot.exists else {
                completion(.failure(self.manager.documentNotFoundError("Report")))
                return
            }

            do {
                let report = try snapshot.data(as: Report.self)
                completion(.success(report))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchReports(
        status: String?,
        completion: @escaping (Result<[Report], Error>) -> Void
    ) {
        let query: Query
        if let status = status {
            query = reportsCollection.whereField("status", isEqualTo: status)
        } else {
            query = reportsCollection
        }

        query.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func updateReport(
        _ report: Report,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let id = report.id else {
            completion(.failure(manager.missingDocumentIdError("Report")))
            return
        }

        do {
            try reportsCollection.document(id).setData(from: report, merge: true) { error in
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

    func deleteReport(
        id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        reportsCollection.document(id).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
}
