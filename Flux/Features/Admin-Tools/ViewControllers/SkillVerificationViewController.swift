import UIKit

class SkillVerificationViewController: UIViewController {

    @IBOutlet weak var SkillsTable: UITableView!

    private var skills: [Skill] = []
    private let viewModel = AdminToolsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        fetchSkills()
    }

    // MARK: - Setup
    private func setupTable() {
        SkillsTable.dataSource = self
        SkillsTable.delegate = self
        SkillsTable.tableFooterView = UIView() // removes empty rows
    }

    private func fetchSkills() {
        // Fetch only pending skills for verification
        viewModel.fetchSkills(filterStatus: .pending) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.skills = data
                    self?.SkillsTable.reloadData()
                case .failure(let error):
                    print("❌ Fetch skills error:", error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension SkillVerificationViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return skills.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SkillCell",
            for: indexPath
        )

        let skill = skills[indexPath.row]

        cell.textLabel?.text = skill.name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        // providerId is available; we can show id until we fetch user details in detail view
        cell.detailTextLabel?.text = "Provider: \(skill.providerId)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .secondaryLabel

        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default

        return cell
    }
}

// MARK: - UITableViewDelegate
extension SkillVerificationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        let selectedSkill = skills[indexPath.row]

        // attempt to push the skill detail view controller from storyboard
        if let vc = storyboard?.instantiateViewController(withIdentifier: "SkillViewController") as? SkillViewController {
            vc.skillID = selectedSkill.id
            vc.viewModel = viewModel
            navigationController?.pushViewController(vc, animated: true)
        } else {
            print("Selected skill:", selectedSkill.name)
        }
    }
}
