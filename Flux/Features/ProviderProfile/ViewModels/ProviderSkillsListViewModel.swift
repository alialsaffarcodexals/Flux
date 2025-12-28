import Foundation

final class ProviderSkillsListViewModel {
    private(set) var skills: [Skill] = []

    var onSkillsUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    func fetchSkills(providerId: String) {
        SkillRepository.shared.fetchSkills(for: providerId) { [weak self] result in
            switch result {
            case .success(let skills):
                self?.skills = skills
                self?.onSkillsUpdated?()
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
}
