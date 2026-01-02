import UIKit

class AccountViewController: UIViewController {

    // MARK: - User Info
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet var suspendOrBanReason: UITextView!
    @IBOutlet weak var profileImageView: UIImageView?
    
    @IBOutlet weak var SuspendButton: UIButton!
    @IBOutlet weak var BanButton: UIButton!
    
    var userID: String?
    var user: User?
    var viewModel: AdminToolsViewModel?
    private let reasonPlaceholder = "Enter a reason to create a report or explain the action..."

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUser()
        suspendOrBanReason?.delegate = self
        setupAdminButtons()
        // Initialize placeholder if empty
        if let tv = suspendOrBanReason, tv.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tv.text = reasonPlaceholder
            tv.textColor = .secondaryLabel
        }
    }

    // Try to find the Suspend/Ban buttons in the view hierarchy and wire them
    private func setupAdminButtons() {
        func findButton(withTitle title: String, in view: UIView) -> UIButton? {
            if let btn = view as? UIButton, btn.currentTitle == title { return btn }
            for sub in view.subviews {
                if let found = findButton(withTitle: title, in: sub) { return found }
            }
            return nil
        }

        if let suspendBtn = findButton(withTitle: "Suspend", in: self.view) {
            suspendBtn.addTarget(self, action: #selector(suspendTapped(_:)), for: .touchUpInside)
        }

        if let banBtn = findButton(withTitle: "Ban", in: self.view) {
            banBtn.addTarget(self, action: #selector(banTapped(_:)), for: .touchUpInside)
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

        // Load profile image for details screen. Prefer active profile mode, then role.
        profileImageView?.image = UIImage(systemName: "person.crop.square")
        profileImageView?.contentMode = .scaleAspectFill
        profileImageView?.clipsToBounds = true
        profileImageView?.layer.cornerRadius = (profileImageView?.frame.height ?? 44) / 2

        // Determine URL to use
        var urlString: String? = nil
        if let mode = user.activeProfileMode {
            urlString = user.profileImageURL(for: mode)
        }
        if urlString == nil {
            // fallback to role preference
            if user.role == .provider {
                urlString = user.providerProfileImageURL ?? user.seekerProfileImageURL
            } else {
                urlString = user.seekerProfileImageURL ?? user.providerProfileImageURL
            }
        }

        if let s = urlString, let url = URL(string: s) {
            URLSession.shared.dataTask(with: url) { data, _, err in
                guard let data = data, let img = UIImage(data: data), err == nil else { return }
                DispatchQueue.main.async {
                    self.profileImageView?.image = img
                    self.profileImageView?.layer.cornerRadius = (self.profileImageView?.frame.height ?? 44) / 2
                    self.profileImageView?.clipsToBounds = true
                }
            }.resume()
        }

        // Update Suspend/Ban button titles and enablement based on current flags
        let suspended = user.isSuspended ?? false
        let banned = user.isBanned ?? false
        // If banned, prefer showing Unban and disable suspend
        if banned {
            BanButton?.setTitle("Unban", for: .normal)
            BanButton?.isEnabled = true
            SuspendButton?.setTitle("Suspend", for: .normal)
            SuspendButton?.isEnabled = false
        } else if suspended {
            // If suspended, show Unsuspend and disable ban
            SuspendButton?.setTitle("Unsuspend", for: .normal)
            SuspendButton?.isEnabled = true
            BanButton?.setTitle("Ban", for: .normal)
            BanButton?.isEnabled = false
        } else {
            // Normal state
            SuspendButton?.setTitle("Suspend", for: .normal)
            SuspendButton?.isEnabled = true
            BanButton?.setTitle("Ban", for: .normal)
            BanButton?.isEnabled = true
        }
    }

    // MARK: - Admin Actions
    @IBAction func suspendTapped(_ sender: UIButton) {
        // Require a reason before allowing suspend
        guard let reason = currentReason() else {
            showAlert(title: "Reason required", message: "Please enter a reason before suspending the user.")
            return
        }

        // Determine if this is an unsuspend action
        if let suspendedUntil = user?.suspendedUntil, let isSusp = user?.isSuspended, isSusp, suspendedUntil > Date() {
            // Unsuspend flow
            showConfirmation(title: "Unsuspend User", message: "Are you sure you want to unsuspend this user?\n\nReason:\n\(reason)") {
                guard let id = self.user?.id else { return }
                sender.isEnabled = false
                sender.setTitle("Unsuspending...", for: .normal)
                self.viewModel?.updateUserFlags(userID: id, isSuspended: false, suspendedUntil: nil, removeSuspendedUntil: true, moderationReason: reason) { [weak self] error in
                    DispatchQueue.main.async {
                        sender.isEnabled = true
                        sender.setTitle("Suspend", for: .normal)
                        if let error = error {
                            print("❌ Unsuspend user error:", error.localizedDescription)
                            self?.showAlert(title: "Error", message: "Failed to unsuspend user.")
                        } else {
                            print("User unsuspended")
                            self?.showAlert(title: "Success", message: "User unsuspended.")
                            // Refresh user state
                            if let id = self?.user?.id { self?.viewModel?.fetchUser(userID: id) { _ in DispatchQueue.main.async { self?.loadUser() } } }
                        }
                    }
                }
            }
            return
        }

        // Normal suspend flow — suspend for 7 days and ensure ban is cleared
        showConfirmation(
            title: "Suspend User",
            message: "Are you sure you want to suspend this user?\n\nReason:\n\(reason)"
        ) {
            guard let id = self.user?.id else { return }
            sender.isEnabled = false
            sender.setTitle("Suspending...", for: .normal)

            let sevenDays = Date().addingTimeInterval(7 * 24 * 60 * 60)
            // Set isSuspended = true, isBanned = false to keep only one flag active
            self.viewModel?.updateUserFlags(userID: id, isSuspended: true, isBanned: false, suspendedUntil: sevenDays, moderationReason: reason) { [weak self] error in
                DispatchQueue.main.async {
                    sender.isEnabled = true
                    sender.setTitle("Suspend", for: .normal)
                    if let error = error {
                        print("❌ Suspend user error:", error.localizedDescription)
                        self?.showAlert(title: "Error", message: "Failed to suspend user.")
                    } else {
                        print("User suspended for 7 days")
                        self?.showAlert(title: "Success", message: "User suspended for 7 days.")
                        // Refresh user state
                        if let id = self?.user?.id { self?.viewModel?.fetchUser(userID: id) { _ in DispatchQueue.main.async { self?.loadUser() } } }
                    }
                }
            }
        }
    }

    @IBAction func banTapped(_ sender: UIButton) {
        // Require a reason before allowing ban
        guard let reason = currentReason() else {
            showAlert(title: "Reason required", message: "Please enter a reason before banning the user.")
            return
        }

        // If currently banned, treat as unban
        if let isBanned = user?.isBanned, isBanned {
            showConfirmation(title: "Unban User", message: "Are you sure you want to unban this user?\n\nReason:\n\(reason)") {
                guard let id = self.user?.id else { return }
                sender.isEnabled = false
                sender.setTitle("Unbanning...", for: .normal)
                self.viewModel?.updateUserFlags(userID: id, isBanned: false, moderationReason: reason) { [weak self] error in
                    DispatchQueue.main.async {
                        sender.isEnabled = true
                        sender.setTitle("Ban", for: .normal)
                        if let error = error {
                            print("❌ Unban user error:", error.localizedDescription)
                            self?.showAlert(title: "Error", message: "Failed to unban user.")
                        } else {
                            print("User unbanned")
                            self?.showAlert(title: "Success", message: "User unbanned.")
                            // Refresh user state
                            if let id = self?.user?.id { self?.viewModel?.fetchUser(userID: id) { _ in DispatchQueue.main.async { self?.loadUser() } } }
                        }
                    }
                }
            }
            return
        }

        // Normal ban flow — make ban exclusive and clear suspension
        showConfirmation(
            title: "Ban User",
            message: "This action is permanent. Continue?\n\nReason:\n\(reason)"
        ) {
            guard let id = self.user?.id else { return }
            sender.isEnabled = false
            sender.setTitle("Banning...", for: .normal)

            // Set isBanned = true and clear suspension flags
            self.viewModel?.updateUserFlags(userID: id, isSuspended: false, isBanned: true, removeSuspendedUntil: true, moderationReason: reason) { [weak self] error in
                DispatchQueue.main.async {
                    sender.isEnabled = true
                    sender.setTitle("Ban", for: .normal)
                    if let error = error {
                        print("❌ Ban user error:", error.localizedDescription)
                        self?.showAlert(title: "Error", message: "Failed to ban user.")
                    } else {
                        print("User banned")
                        self?.showAlert(title: "Success", message: "User banned.")
                        // Refresh user state
                        if let id = self?.user?.id { self?.viewModel?.fetchUser(userID: id) { _ in DispatchQueue.main.async { self?.loadUser() } } }
                    }
                }
            }
        }
    }

    // Return trimmed reason text if it's provided and not the placeholder
    private func currentReason() -> String? {
        guard let tv = suspendOrBanReason else { return nil }
        let text = tv.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return nil }
        if text == reasonPlaceholder { return nil }
        return text
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
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
