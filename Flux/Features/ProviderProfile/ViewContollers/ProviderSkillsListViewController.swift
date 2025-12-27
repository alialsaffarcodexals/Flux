import UIKit
import FirebaseAuth

final class ProviderSkillsListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView?

    private let viewModel = ProviderSkillsListViewModel()
    private var selectedSkill: Skill?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.dataSource = self
        tableView?.delegate = self
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSkills()
    }

    private func setupBindings() {
        viewModel.onSkillsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView?.reloadData()
            }
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }
    }

    private func refreshSkills() {
        guard let providerId = Auth.auth().currentUser?.uid else { return }
        viewModel.fetchSkills(providerId: providerId)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? SkillDetailsViewController else {
            return
        }

        if let skill = selectedSkill {
            destination.configure(with: skill)
            return
        }

        if let indexPath = tableView?.indexPathForSelectedRow {
            let skill = viewModel.skills[indexPath.row]
            destination.configure(with: skill)
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ProviderSkillsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.skills.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SkillListCell", for: indexPath)
        let skill = viewModel.skills[indexPath.row]

        let labels = cell.contentView.subviews.compactMap { $0 as? UILabel }
            .sorted { $0.frame.minX < $1.frame.minX }

        if labels.indices.contains(0) {
            labels[0].text = skill.name
        } else {
            cell.textLabel?.text = skill.name
        }

        let statusText = statusDisplayText(for: skill.status)
        if labels.indices.contains(1) {
            labels[1].text = statusText
            labels[1].textColor = statusColor(for: skill.status)
        } else {
            cell.detailTextLabel?.text = statusText
            cell.detailTextLabel?.textColor = statusColor(for: skill.status)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSkill = viewModel.skills[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func statusDisplayText(for status: SkillStatus) -> String {
        switch status {
        case .approved:
            return "Verified"
        case .pending:
            return "Pending"
        case .rejected:
            return "Rejected"
        }
    }

    private func statusColor(for status: SkillStatus) -> UIColor {
        switch status {
        case .approved:
            return .systemGreen
        case .pending:
            return .systemOrange
        case .rejected:
            return .systemRed
        }
    }
}
