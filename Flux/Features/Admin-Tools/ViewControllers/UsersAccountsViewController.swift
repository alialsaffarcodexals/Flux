import UIKit

class UsersAccountsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private let viewModel = AdminToolsViewModel()
    private var users: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        fetchUsers()
    }

    private func fetchUsers() {
        viewModel.fetchUsers() { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
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
        return users.count
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

        // Dummy avatar
        cell.imageView?.image = UIImage(systemName: "person.crop.square")
        cell.imageView?.tintColor = .systemGray
        cell.imageView?.contentMode = .scaleAspectFill

        return cell
    }
}

// MARK: - UITableViewDelegate
extension UsersAccountsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        // Let the prototype cell's segue (defined in storyboard) run automatically.
        // Avoid changing selection here so `prepare(for:sender:)` can derive the indexPath from the sender cell.
        // Deselect after a short delay so the transition is smooth.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? AccountViewController {
            if let userSender = sender as? User {
                dest.userID = userSender.id
            } else if let cell = sender as? UITableViewCell,
                      let indexPath = tableView.indexPath(for: cell) {
                let selectedUser = users[indexPath.row]
                dest.userID = selectedUser.id
            } else if let indexPath = tableView.indexPathForSelectedRow {
                let selectedUser = users[indexPath.row]
                dest.userID = selectedUser.id
            }
            dest.viewModel = viewModel
        }
    }
}
