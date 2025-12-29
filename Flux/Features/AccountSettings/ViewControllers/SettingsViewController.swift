import UIKit

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
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
            print("🔴 Error signing out: \(error)")
            let alert = UIAlertController(title: "Error", message: "Failed to sign out: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
