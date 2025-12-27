import UIKit

class AccountViewController: UIViewController {

    // MARK: - User Info
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet var suspendOrBanReason: UITextView!
    
    var userID: String?
    var user: User?
    var viewModel: AdminToolsViewModel?
    private let reasonPlaceholder = "Enter a reason to create a report or explain the action..."

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUser()
        suspendOrBanReason?.delegate = self
        // Initialize placeholder if empty
        if let tv = suspendOrBanReason, tv.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tv.text = reasonPlaceholder
            tv.textColor = .secondaryLabel
        }
    }

    private func loadUser() {
        guard let id = userID else { return }
        viewModel?.fetchUser(userID: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let u):
                    self?.user = u
                    self?.populate(with: u)
                    self?.loadReportsForUser()
                case .failure(let error):
                    print("❌ Fetch user error:", error.localizedDescription)
                }
            }
        }
    }

    private func loadReportsForUser() {
        guard let id = user?.id else {
            // clear or prompt
            if let tv = suspendOrBanReason {
                tv.text = reasonPlaceholder
                tv.textColor = .secondaryLabel
            }
            return
        }

        viewModel?.fetchReportsForUser(reportedUserID: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reports):
                    if let first = reports.first {
                        // Prefer the report `reason` field; fall back to `description`.
                        let reasonText = (first.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? first.description : first.reason)
                        if reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            // No reason/description provided — show placeholder
                            self?.suspendOrBanReason?.text = self?.reasonPlaceholder
                            self?.suspendOrBanReason?.textColor = .secondaryLabel
                        } else {
                            self?.suspendOrBanReason?.text = reasonText
                            self?.suspendOrBanReason?.textColor = .label
                        }
                    } else {
                        if let tv = self?.suspendOrBanReason {
                            tv.text = self?.reasonPlaceholder
                            tv.textColor = .secondaryLabel
                        }
                    }
                case .failure(let error):
                    print("❌ Fetch reports for user error:", error.localizedDescription)
                    if let tv = self?.suspendOrBanReason {
                        tv.text = self?.reasonPlaceholder
                        tv.textColor = .secondaryLabel
                    }
                }
            }
        }
    }

    private func populate(with user: User) {
        // Prefer computed `name`, fall back to first/last or displayName, then a placeholder.
        // Warn if outlets are not connected to help debugging nil unwrap crashes.
        if nameLabel == nil || usernameLabel == nil || suspendOrBanReason == nil {
            print("⚠️ AccountViewController: one or more IBOutlets are not connected.")
        }

        let fullName = user.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fullName.isEmpty {
            nameLabel?.text = fullName
        } else {
            let f = user.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            let l = user.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            let combo = ([f, l].filter { !$0.isEmpty }).joined(separator: " ")
            nameLabel?.text = combo.isEmpty ? "(No name)" : combo
        }

        // Username: prefer `username`, then email prefix, then user id
        var username = user.username.trimmingCharacters(in: .whitespacesAndNewlines)
        if username.isEmpty, !user.email.isEmpty {
            let email = user.email
            username = String(email.split(separator: "@").first ?? "")
        }
        if username.isEmpty {
            usernameLabel?.text = "(no username)"
        } else {
            usernameLabel?.text = "@\(username)"
        }
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
            guard let id = self.user?.id else { return }
            self.viewModel?.updateUserFlags(userID: id, isSuspended: true) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Suspend user error:", error.localizedDescription)
                    } else {
                        print("User suspended")
                    }
                }
            }
        }
    }

    @IBAction func banTapped(_ sender: UIButton) {
        showConfirmation(
            title: "Ban User",
            message: "This action is permanent. Continue?"
        ) {
            guard let id = self.user?.id else { return }
            self.viewModel?.updateUserFlags(userID: id, isBanned: true) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Ban user error:", error.localizedDescription)
                    } else {
                        print("User banned")
                    }
                }
            }
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

// MARK: - UITextViewDelegate
extension AccountViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
          if textView == suspendOrBanReason,
              textView.text == reasonPlaceholder {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == suspendOrBanReason,
           textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = reasonPlaceholder
            textView.textColor = .secondaryLabel
        }
    }
}
