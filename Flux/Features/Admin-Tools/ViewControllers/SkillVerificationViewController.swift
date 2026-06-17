import UIKit
import FirebaseFirestore

class SkillVerificationViewController: UIViewController {

    @IBOutlet weak var SkillsTable: UITableView!
    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var SegmentControl: UISegmentedControl!

    private var allSkills: [Skill] = []
    private var skills: [Skill] = []

    var initialSkills: [Skill]?
    var viewModel: AdminToolsViewModel? = AdminToolsViewModel()

    //  Cache to avoid refetching users on scroll
    private var userNameCache: [String: String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupSearchBar()

        SegmentControl.addTarget(
            self,
            action: #selector(segmentChanged(_:)),
            for: .valueChanged
        )

        if let prefetched = initialSkills {
            allSkills = prefetched
            updateDisplayedSkills()
        } else {
            fetchSkills()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSkills()
    }

    // MARK: - Setup

    private func setupTable() {
        SkillsTable.dataSource = self
        SkillsTable.delegate = self
        SkillsTable.tableFooterView = UIView()
    }

    private func setupSearchBar() {
        SearchBar.delegate = self
        SearchBar.placeholder = "Search skills"
        SearchBar.autocapitalizationType = .none
    }

    // MARK: - Fetch

    private func fetchSkills() {
        guard let vm = viewModel else { return }

        vm.fetchSkills(filterStatus: nil) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.allSkills = data
                    self?.updateDisplayedSkills()
                case .failure(let error):
                    print("Fetch skills error:", error.localizedDescription)
                }
            }
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        SearchBar.resignFirstResponder()
        updateDisplayedSkills()
    }

    private func updateDisplayedSkills() {
        var filtered = allSkills

        switch SegmentControl.selectedSegmentIndex {
        case 0:
            filtered = filtered.filter { $0.status == .pending }
        case 1:
            filtered = filtered.filter { $0.status == .approved }
        case 2:
            filtered = filtered.filter { $0.status == .rejected }
        default:
            break
        }

        if let text = SearchBar.text?.lowercased(),
           !text.isEmpty {
            filtered = filtered.filter {
                $0.name.lowercased().contains(text)
            }
        }

        skills = filtered
        SkillsTable.reloadData()
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

        let statusColor: UIColor
        switch skill.status {
        case .approved:
            statusColor = .systemGreen
        case .pending:
            statusColor = .systemOrange
        case .rejected:
            statusColor = .systemRed
        }

        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = statusColor

        let providerId = skill.providerId

        //  Use cached username if available
        if let cachedName = userNameCache[providerId] {
            cell.detailTextLabel?.text = "Submitted by: \(cachedName)"
        } else {
            cell.detailTextLabel?.text = "Submitted by: \(providerId)"

            viewModel?.fetchUser(userID: providerId) { [weak self, weak tableView] result in
                guard let self = self else { return }

                if case .success(let user) = result {
                    let fullName = "\(user.firstName) \(user.lastName)"
                    self.userNameCache[providerId] = fullName

                    DispatchQueue.main.async {
                        if let current = tableView?.cellForRow(at: indexPath) {
                            current.detailTextLabel?.text = "Submitted by: \(fullName)"
                            current.detailTextLabel?.textColor = statusColor
                        }
                    }
                }
            }
        }

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

        if let vc = storyboard?
            .instantiateViewController(
                withIdentifier: "SkillViewController"
            ) as? SkillViewController {

            vc.skillID = selectedSkill.id
            vc.skill = selectedSkill
            vc.viewModel = viewModel

            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UISearchBarDelegate

extension SkillVerificationViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
        updateDisplayedSkills()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        updateDisplayedSkills()
    }
}
