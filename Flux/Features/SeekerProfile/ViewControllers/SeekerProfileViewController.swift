// File: Flux/Features/SeekerProfile/Storyboards/SeekerProfileViewController.swift

import UIKit

class SeekerProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    @IBOutlet weak var providerProfileButton: UIButton!
    
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var favoritesButton: UIButton!
    
    var viewModel = SeekerProfileViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        // 🚀 Fetch fresh data every time the view loads to ensure sync with Provider updates
        viewModel.fetchUserProfile()
        
        // ❌ REMOVED: locationLabel.text = "Bahrain 🇧🇭"
        // The label is now controlled solely by setupBindings()
    }
    
    @IBAction func providerProfileTapped(_ sender: UIButton) {
        // Switch to Provider Mode
        if let tabBarController = self.tabBarController as? MainTabBarController {
            tabBarController.switchRole(to: .provider)
        }
    }
    
    @IBAction func historyButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "History", bundle: nil)
        if let historyVC = storyboard.instantiateViewController(withIdentifier: "HistoryViewController") as? HistoryVC {
            navigationController?.pushViewController(historyVC, animated: true)
        } else {
             print("Error: Could not instantiate HistoryViewController with ID 'HistoryViewController'")
        }
    }

    @IBAction func favoritesButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Favorites", bundle: nil)
        if let favoritesVC = storyboard.instantiateViewController(withIdentifier: "FavoritesViewController") as? FavoritesVC {
            navigationController?.pushViewController(favoritesVC, animated: true)
        } else {
            print("Error: Could not instantiate FavoritesViewController with ID 'FavoritesViewController'")
        }
    }
    
    @IBAction func settingsTapped(_ sender: Any) {
        print("⚙️ Settings Tapped in Seeker Profile")
        
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        
        guard let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else {
            print("🔴 Error: Could not find 'SettingsViewController' in Settings.storyboard")
            return
        }
        
        // Push onto existing navigation stack (preserves Back button)
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    func setupBindings() {
        viewModel.onUserDataUpdated = { [weak self] user in
            DispatchQueue.main.async {
                self?.nameLabel.text = user.name
                self?.usernameLabel.text = "@\(user.username)"
                
                // 📍 Displays "Bahrain" (default) OR updated Provider location
                self?.locationLabel.text = user.location
                
                // Safety: Optional chain phoneLabel in case it's not connected
                self?.phoneLabel?.text = user.phoneNumber ?? "Not set"
                
                if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                    // Optimized image loading (placeholder logic recommended)
                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url) {
                            DispatchQueue.main.async {
                                self?.profileImageView.image = UIImage(data: data)
                            }
                        }
                    }
                }
            }
        }
        
        viewModel.onNavigateToProviderSetup = { [weak self] in
            let storyboard = UIStoryboard(name: "ProviderProfile", bundle: nil)
            if let introVC = storyboard.instantiateViewController(withIdentifier: "ProviderSetupViewController") as? ProviderIntroViewController {
                introVC.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(introVC, animated: true)
            }
        }
        
        viewModel.onError = { errorMessage in
            print("Error fetching profile: \(errorMessage)")
        }
        
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.showLoadingIndicator()
                } else {
                    self?.hideLoadingIndicator()
                }
            }
        }
    }
}
