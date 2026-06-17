import Foundation

final class SkillDetailsViewModel {
    private(set) var skill: Skill

    var onDeleteSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    init(skill: Skill) {
        self.skill = skill
    }

    func deleteSkill() {
        guard let id = skill.id else {
            onError?("Skill ID is missing.")
            return
        }

        SkillRepository.shared.deleteSkill(id: id) { [weak self] result in
            switch result {
            case .success:
                self?.onDeleteSuccess?()
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
}
