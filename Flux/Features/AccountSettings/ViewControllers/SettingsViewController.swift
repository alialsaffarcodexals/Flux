import UIKit
import FirebaseAuth

class SettingsViewController: UITableViewController {
    
    private let settingsManager = AppSettingsManager.shared

    // MARK: - Outlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        // Apply initial fonts
        settingsManager.applyFonts(to: self.view)
        
        // Observe font size changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fontSizeDidChange),
            name: AppNotifications.fontSizeDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reapply fonts when view appears
        settingsManager.applyFonts(to: self.view)
        
        //  Fetch and update user profile data
        fetchUserProfile()
    }
    
    @objc private func fontSizeDidChange() {
        print("SettingsViewController received fontSizeDidChange notification")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Apply fonts to entire view hierarchy
            self.settingsManager.applyFonts(to: self.view)
            // Reload table to update all cells
            self.tableView.reloadData()
            print("SettingsViewController fonts updated")
        }
    }
    
    // MARK: - Data Fetching
    private func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        UserRepository.shared.getUser(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.updateUI(with: user)
                case .failure(let error):
                    print("Error fetching user profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateUI(with user: User) {
        // Update Username Label if connected
        usernameLabel?.text = "@\(user.username)"
        
        // Always show seeker profile image in settings
        if let imageURL = user.profileImageURL(for: .buyerMode), !imageURL.isEmpty, let url = URL(string: imageURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImageView?.image = image
                    }
                }
            }
        } else {
            // No custom image, keep default (person.circle) from storyboard
             // Optionally ensure it is reset if cell reuse was an issue (not for static cells)
        }
    }

    // MARK: - Table View Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Check if "Log out" section is tapped (Assuming Section 2 based on current Storyboard)
        if indexPath.section == 2 {
             showLogoutConfirmation()
        }
    }
    
    private func showLogoutConfirmation() {
        let alert = UIAlertController(title: "Sign Out", message: "Would you like to sign out?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            self?.performLogout()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(signOutAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func performLogout() {
        do {
            try AuthManager.shared.signOut()
            AppNavigator.shared.navigateToAuth()
        } catch {
            print("Error signing out: \(error)")
            let alert = UIAlertController(title: "Error", message: "Failed to sign out: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
