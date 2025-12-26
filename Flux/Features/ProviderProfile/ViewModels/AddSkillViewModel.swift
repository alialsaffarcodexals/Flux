import Foundation
import UIKit

final class AddSkillViewModel {
    var onSaveSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    func uploadProofImage(
        _ image: UIImage,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        StorageManager.shared.uploadSkillProofImage(image: image) { result in
            completion(result)
        }
    }

    func saveSkill(
        providerId: String,
        name: String,
        level: SkillLevel,
        description: String?,
        proofImageURL: String
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            onError?("Please enter a skill name.")
            return
        }

        guard !proofImageURL.isEmpty else {
            onError?("Please upload a proof image.")
            return
        }

        createSkill(
            providerId: providerId,
            name: trimmedName,
            level: level,
            description: description,
            proofImageURL: proofImageURL
        )
    }

    private func createSkill(
        providerId: String,
        name: String,
        level: SkillLevel,
        description: String?,
        proofImageURL: String?
    ) {
        let skill = Skill(
            id: nil,
            providerId: providerId,
            name: name,
            level: level,
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines),
            proofImageURL: proofImageURL,
            status: .pending,
            adminFeedback: nil
        )

        SkillRepository.shared.createSkill(skill) { [weak self] result in
            switch result {
            case .success:
                self?.onSaveSuccess?()
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
}
