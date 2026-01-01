import UIKit
import FirebaseFirestore

class SkillVerificationViewController: UIViewController {

    @IBOutlet weak var SkillsTable: UITableView!
    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var SegmentControl: UISegmentedControl!
    
    private var allSkills: [Skill] = []   // original data
    private var skills: [Skill] = []      // filtered data
    // Optional preloaded skills to show immediately
    var initialSkills: [Skill]?
    
    var viewModel: AdminToolsViewModel? = AdminToolsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupSearchBar()
        // Ensure segment control sends events and set initial index
        SegmentControl?.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        SegmentControl?.selectedSegmentIndex = SegmentControl?.selectedSegmentIndex ?? 0
        // Use prefetched skills if available
        if let prefetched = initialSkills {
            allSkills = prefetched
            // apply current filters immediately
            updateDisplayedSkills()
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
                    // apply current filters (segment + search)
                    self?.updateDisplayedSkills()
                case .failure(let error):
                    print("❌ Fetch skills error:", error.localizedDescription)
                }
            }
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        // Re-apply filters when segment changes
        SearchBar?.resignFirstResponder()
        updateDisplayedSkills()
    }

    private func updateDisplayedSkills() {
        // Start from all skills, apply segment filter, then search filter
        var filtered = allSkills

        if let sc = SegmentControl {
            switch sc.selectedSegmentIndex {
            case 0:
                // Pending
                filtered = filtered.filter { $0.status == .pending }
            case 1:
                // Approved
                filtered = filtered.filter { $0.status == .approved }
            case 2:
                // Rejected
                filtered = filtered.filter { $0.status == .rejected }
            default:
                break
            }
        }

        if let query = SearchBar?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let q = query.lowercased()
            filtered = filtered.filter { $0.name.lowercased().contains(q) }
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

        // Fetch skill document timestamp if available; otherwise show Unknown
        if let skillId = skill.id {
            let db = Firestore.firestore()
            db.collection("skills").document(skillId).getDocument { snap, _ in
                DispatchQueue.main.async {
                    var timeText = "Unknown"
                    if let data = snap?.data() {
                        if let ts = data["createdAt"] as? Timestamp {
                            let d = ts.dateValue()
                            let fmt = DateFormatter()
                            fmt.dateStyle = .medium
                            fmt.timeStyle = .short
                            timeText = fmt.string(from: d)
                        } else if let s = data["createdAt"] as? String {
                            timeText = s
                        }
                    }

                    if let current = tableView.cellForRow(at: indexPath) {
                        let base = current.detailTextLabel?.text ?? "Provider: \(skill.providerId) • Status: \(statusText)"
                        current.detailTextLabel?.text = base + " • Time: \(timeText)"
                        current.detailTextLabel?.textColor = statusColor
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

        // Use the unified filter so search applies to the currently selected segment
        updateDisplayedSkills()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        updateDisplayedSkills()
    }
}
