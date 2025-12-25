import Foundation
import FirebaseFirestore

final class SkillRepository {
    static let shared = SkillRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var skillsCollection: CollectionReference {
        manager.db.collection("skills")
    }

    func createSkill(
        _ skill: Skill,
        completion: @escaping (Result<Skill, Error>) -> Void
    ) {
        let document = skillsCollection.document()
        do {
            try document.setData(from: skill) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdSkill = skill
                createdSkill.id = document.documentID
                completion(.success(createdSkill))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchSkill(
        by id: String,
        completion: @escaping (Result<Skill, Error>) -> Void
    ) {
        skillsCollection.document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(self.manager.missingSnapshotError()))
                return
            }

            guard snapshot.exists else {
                completion(.failure(self.manager.documentNotFoundError("Skill")))
                return
            }

            do {
                let skill = try snapshot.data(as: Skill.self)
                completion(.success(skill))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchSkills(
        providerId: String,
        status: SkillStatus?,
        completion: @escaping (Result<[Skill], Error>) -> Void
    ) {
        var query: Query = skillsCollection.whereField("providerId", isEqualTo: providerId)
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        query.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func updateSkill(
        _ skill: Skill,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let id = skill.id else {
            completion(.failure(manager.missingDocumentIdError("Skill")))
            return
        }

        do {
            try skillsCollection.document(id).setData(from: skill, merge: true) { error in
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

    func deleteSkill(
        id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        skillsCollection.document(id).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
}
