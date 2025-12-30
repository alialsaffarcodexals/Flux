import UIKit

class UsersAccountsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var SearchBar: UISearchBar!
    
    var viewModel: AdminToolsViewModel? = AdminToolsViewModel()
    
    private var allUsers: [User] = []   // original data
    private var users: [User] = []      // filtered data
    // Optional preloaded users to show immediately
    var initialUsers: [User]?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard tableView != nil else {
            print("⚠️ UsersAccountsViewController: tableView outlet is not connected.")
            return
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        SearchBar.delegate = self
        SearchBar.placeholder = "Search users"
        SearchBar.autocapitalizationType = .none

        // Use prefetched users if available
        if let prefetched = initialUsers {
            allUsers = prefetched
            users = prefetched
            tableView.reloadData()
        } else {
            fetchUsers()
        }
    }

    private func fetchUsers() {
        guard let vm = viewModel else {
            print("⚠️ UsersAccountsViewController: viewModel is nil, cannot fetch users")
            return
        }

        vm.fetchUsers() { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.allUsers = data
                    self?.users = data
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("❌ Fetch users error:", error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension UsersAccountsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "UserCell",
            for: indexPath
        )

        let user = users[indexPath.row]

        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = "@\(user.username)"

        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .secondaryLabel

        cell.imageView?.image = UIImage(systemName: "person.crop.square")
        cell.imageView?.tintColor = .systemGray

        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate
extension UsersAccountsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? AccountViewController {

            if let cell = sender as? UITableViewCell,
               let indexPath = tableView.indexPath(for: cell) {

                let selectedUser = users[indexPath.row]
                dest.userID = selectedUser.id
            }

            dest.viewModel = viewModel
        }
    }
}

// MARK: - UISearchBarDelegate
extension UsersAccountsViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            users = allUsers
        } else {
            users = allUsers.filter {
                $0.name.lowercased().contains(query.lowercased()) ||
                $0.username.lowercased().contains(query.lowercased())
            }
        }

        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        users = allUsers
        tableView.reloadData()
    }
}
