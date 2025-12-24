import UIKit

class UsersAccountsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    struct User {
        let name: String
        let username: String
    }

    private let users: [User] = [
        User(name: "Haitham Rashdan", username: "@haitham79"),
        User(name: "Ali Mohammed", username: "@ali_dev"),
        User(name: "Sara Ahmed", username: "@sara_a"),
        User(name: "John Smith", username: "@john_smith")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
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
        cell.detailTextLabel?.text = user.username

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
        tableView.deselectRow(at: indexPath, animated: true)

        let selectedUser = users[indexPath.row]
        print("Selected user:", selectedUser)
        // later: push User Account details screen
    }
}
