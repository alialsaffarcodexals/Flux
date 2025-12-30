import UIKit

class SkillVerificationViewController: UIViewController {

    @IBOutlet weak var SkillsTable: UITableView!
    @IBOutlet weak var SearchBar: UISearchBar!
    
    private var allSkills: [Skill] = []   // original data
    private var skills: [Skill] = []      // filtered data
    // Optional preloaded skills to show immediately
    var initialSkills: [Skill]?
    
    var viewModel: AdminToolsViewModel? = AdminToolsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupSearchBar()
        // Use prefetched skills if available
        if let prefetched = initialSkills {
            allSkills = prefetched
            skills = prefetched
            SkillsTable.reloadData()
        } else {
            fetchSkills()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh skills list when returning from detail (approve/reject)
        fetchSkills()
    }

    // MARK: - Setup
    private func setupTable() {
        SkillsTable.dataSource = self
        SkillsTable.delegate = self
        SkillsTable.tableFooterView = UIView()
        SkillsTable.allowsSelection = true
    }

    private func setupSearchBar() {
        SearchBar.delegate = self
        SearchBar.placeholder = "Search skills"
        SearchBar.autocapitalizationType = .none
    }

    // MARK: - Fetch
    private func fetchSkills() {
        guard let vm = viewModel else {
            print("⚠️ SkillVerificationViewController: viewModel is nil, cannot fetch skills")
            return
        }

        vm.fetchSkills(filterStatus: nil) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.allSkills = data
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
        skills.count
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

        let statusText: String
        let statusColor: UIColor
        switch skill.status {
        case .approved:
            statusText = "Accepted"
            statusColor = .systemGreen
        case .pending:
            statusText = "Pending"
            statusColor = .systemOrange
        case .rejected:
            statusText = "Rejected"
            statusColor = .systemRed
        }

        cell.detailTextLabel?.text = "Provider: \(skill.providerId) • Status: \(statusText)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = statusColor

        // Replace providerId with readable username when available
        if let vm = viewModel {
            vm.fetchUser(userID: skill.providerId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        if let current = tableView.cellForRow(at: indexPath) {
                            current.detailTextLabel?.text = "Provider: @\(user.username) • Status: \(statusText)"
                            current.detailTextLabel?.textColor = statusColor
                        }
                    case .failure:
                        break
                    }
                }
            }
        }

        // Make non-pending skills non-interactive
        if skill.status == .pending {
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.isUserInteractionEnabled = true
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = false
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension SkillVerificationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let selectedSkill = skills[indexPath.row]

        // Do nothing for non-pending skills
        guard selectedSkill.status == .pending else { return }

        if let vc = storyboard?.instantiateViewController(withIdentifier: "SkillViewController") as? SkillViewController {
            vc.skillID = selectedSkill.id
            vc.skill = selectedSkill
            vc.viewModel = viewModel

            if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension SkillVerificationViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            skills = allSkills
        } else {
            skills = allSkills.filter {
                $0.name.lowercased().contains(query.lowercased())
            }
        }

        SkillsTable.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        skills = allSkills
        SkillsTable.reloadData()
    }
}
