import UIKit

class AccountViewController: UIViewController {

    // MARK: - User Info
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDummyUser()
    }

    // MARK: - Dummy Data
    private func setupDummyUser() {
        nameLabel.text = "Haitham Rashdan"
        usernameLabel.text = "@haitham79"
    }

    // MARK: - Navigation Actions
    @IBAction func reportsTapped(_ sender: UIButton) {
        print("Reports tapped")
        // navigate to user's reports
    }

    @IBAction func warningsTapped(_ sender: UIButton) {
        print("Warnings tapped")
        // navigate to user's warnings
    }

    @IBAction func activityTapped(_ sender: UIButton) {
        print("Activity tapped")
        // navigate to user activity
    }

    // MARK: - Admin Actions
    @IBAction func suspendTapped(_ sender: UIButton) {
        showConfirmation(
            title: "Suspend User",
            message: "Are you sure you want to suspend this user?"
        ) {
            print("User suspended")
        }
    }

    @IBAction func banTapped(_ sender: UIButton) {
        showConfirmation(
            title: "Ban User",
            message: "This action is permanent. Continue?"
        ) {
            print("User banned")
        }
    }

    // MARK: - Alert Helper
    private func showConfirmation(title: String,
                                  message: String,
                                  confirmAction: @escaping () -> Void) {

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
            confirmAction()
        })

        present(alert, animated: true)
    }
}
