import UIKit

class SkillViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var providerName: UILabel!
    @IBOutlet weak var providerUserName: UILabel!
    @IBOutlet weak var skillName: UILabel!
    @IBOutlet weak var skillLevel: UILabel!
    @IBOutlet weak var approveButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!

    var skillID: String?
    var skill: Skill?
    var viewModel: AdminToolsViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }

    // MARK: - Dummy Data (for testing UI)
    private func loadDummyData() {
        providerName.text = "Ali Mohammed"
        providerUserName.text = "@sdklfh95"
        skillName.text = "Advance Plumbing"
        skillLevel.text = "Expert"
    }

    private func loadData() {
        guard let id = skillID else {
            // if skill already provided, populate
            if let skill = skill {
                populate(with: skill)
            }
            return
        }

        viewModel?.fetchSkill(by: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let s):
                    self?.skill = s
                    self?.populate(with: s)
                    // also fetch provider name
                    self?.viewModel?.fetchUser(userID: s.providerId) { userResult in
                        DispatchQueue.main.async {
                            switch userResult {
                            case .success(let user):
                                self?.providerName.text = user.name
                                self?.providerUserName.text = "@\(user.username)"
                            case .failure:
                                self?.providerName.text = s.providerId
                                self?.providerUserName.text = ""
                            }
                        }
                    }
                case .failure(let error):
                    print("❌ Fetch skill error:", error.localizedDescription)
                }
            }
        }
    }

    private func populate(with skill: Skill) {
        skillName.text = skill.name
        skillLevel.text = skill.status.rawValue
    }

    @IBAction func approveTapped(_ sender: UIButton) {
        guard let skill = skill else { return }
        approveButton.isEnabled = false
        viewModel?.updateSkillStatus(skillID: skill.id ?? "", status: .approved) { [weak self] error in
            DispatchQueue.main.async {
                self?.approveButton.isEnabled = true
                if let error = error {
                    print("❌ Approve error:", error.localizedDescription)
                } else {
                    self?.skillLevel.text = SkillStatus.approved.rawValue
                }
            }
        }
    }

    @IBAction func rejectTapped(_ sender: UIButton) {
        guard let skill = skill else { return }
        // present simple feedback alert
        let alert = UIAlertController(title: "Reject Skill", message: "Provide feedback (optional)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Feedback for provider" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            let feedback = alert.textFields?.first?.text
            self?.viewModel?.updateSkillStatus(skillID: skill.id ?? "", status: .rejected, adminFeedback: feedback) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Reject error:", error.localizedDescription)
                    } else {
                        self?.skillLevel.text = SkillStatus.rejected.rawValue
                    }
                }
            }
        })

        present(alert, animated: true)
    }
}
