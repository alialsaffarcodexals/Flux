import UIKit

class SkillVerificationViewController: UIViewController {

    @IBOutlet weak var SkillsTable: UITableView!

    // MARK: - Data Model
    struct SkillItem {
        let title: String
        let submittedBy: String
    }

    private var skills: [SkillItem] = [
        SkillItem(title: "Advance Plumbing", submittedBy: "Ali Mohammed"),
        SkillItem(title: "Carpentry", submittedBy: "John Cena"),
        SkillItem(title: "Electrical Wiring", submittedBy: "Jaffer Abdullah")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
    }

    // MARK: - Setup
    private func setupTable() {
        SkillsTable.dataSource = self
        SkillsTable.delegate = self
        SkillsTable.tableFooterView = UIView() // removes empty rows
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

        cell.textLabel?.text = skill.title
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        cell.detailTextLabel?.text = "Submitted by: \(skill.submittedBy)"
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
        print("Selected skill:", selectedSkill.title)

        // Later:
        // push SkillDetailsViewController
    }
}
