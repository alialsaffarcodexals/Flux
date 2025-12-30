import UIKit

final class SkillDetailsViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var statusMessageLabel: UILabel?
    @IBOutlet weak var statusContainerView: UIView?
    @IBOutlet weak var levelButton: UIButton?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var proofButton: UIButton?
    @IBOutlet weak var deleteButton: UIButton?

    var skill: Skill?
    private var viewModel: SkillDetailsViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        ensureViewModel()
        updateUI()
    }

    func configure(with skill: Skill) {
        self.skill = skill
        viewModel = SkillDetailsViewModel(skill: skill)
        bindViewModel()
        if isViewLoaded {
            updateUI()
        }
    }

    private func bindViewModel() {
        viewModel?.onDeleteSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }

        viewModel?.onError = { [weak self] message in
            self?.showAlert(message: message)
        }
    }

    @IBAction private func deleteTapped(_ sender: UIButton) {
        ensureViewModel()
        guard viewModel != nil else {
            showAlert(message: "Unable to delete this skill.")
            return
        }

        let alert = UIAlertController(
            title: "Confirm Deletion",
            message: "Are you sure you want to delete this skill?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel?.deleteSkill()
        })
        present(alert, animated: true)
    }

    private func ensureViewModel() {
        if viewModel == nil, let skill = skill {
            viewModel = SkillDetailsViewModel(skill: skill)
            bindViewModel()
        }
    }

    private func updateUI() {
        guard let skill = viewModel?.skill ?? skill else { return }

        nameLabel?.text = skill.name
        descriptionLabel?.text = skill.description ?? "No description provided."

        let levelText = skill.level?.rawValue ?? "Beginner"
        applyPillStyle(title: levelText, toButton: levelButton)

        let statusText = statusDisplayText(for: skill.status)
        statusLabel?.text = "Status: \(statusText)"
        statusLabel?.textColor = .label
        statusMessageLabel?.text = statusMessage(for: skill.status, adminFeedback: skill.adminFeedback)
        statusContainerView?.backgroundColor = statusBackgroundColor(for: skill.status)

        let proofText = proofDisplayName(urlString: skill.proofImageURL)
        applyPillStyle(title: proofText, toButton: proofButton)
    }

    private func statusDisplayText(for status: SkillStatus) -> String {
        switch status {
        case .approved:
            return "Verified"
        case .pending:
            return "Pending Review"
        case .rejected:
            return "Rejected"
        }
    }

    private func statusBackgroundColor(for status: SkillStatus) -> UIColor {
        switch status {
        case .approved:
            return UIColor.systemGreen.withAlphaComponent(0.2)
        case .pending:
            return UIColor.systemYellow.withAlphaComponent(0.2)
        case .rejected:
            return UIColor.systemRed.withAlphaComponent(0.2)
        }
    }

    private func statusMessage(for status: SkillStatus, adminFeedback: String?) -> String {
        switch status {
        case .approved:
            return "This skill has been successfully added to your public profile."
        case .pending:
            return "Your skill is being reviewed by an admin."
        case .rejected:
            let feedback = adminFeedback?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !feedback.isEmpty {
                return "Reason: \(feedback)"
            }
            return "This skill was rejected. Please update and resubmit."
        }
    }

    private func proofDisplayName(urlString: String?) -> String {
        guard let urlString = urlString, !urlString.isEmpty else {
            return "No proof uploaded"
        }

        if let url = URL(string: urlString) {
            return url.lastPathComponent
        }

        return "No proof uploaded"
    }

    private func applyPillStyle(title: String, toButton button: UIButton?) {
        if let button = button {
            if var config = button.configuration {
                config.title = title
                config.baseBackgroundColor = .systemGray4
                config.baseForegroundColor = .black
                button.configuration = config
            } else {
                button.setTitle(title, for: .normal)
                button.setTitleColor(.black, for: .normal)
                button.backgroundColor = .systemGray4
            }
            button.isUserInteractionEnabled = false
            button.layer.cornerRadius = 16
            button.clipsToBounds = true
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
