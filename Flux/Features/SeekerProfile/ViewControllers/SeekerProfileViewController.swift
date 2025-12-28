// File: Flux/Features/SeekerProfile/Storyboards/SeekerProfileViewController.swift

import UIKit

class SeekerProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var providerProfileButton: UIButton!
    
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
        //viewModel.didTapServiceProviderProfile()
        
        // Switch to Provider Mode
        if let tabBarController = self.tabBarController as? MainTabBarController {
            tabBarController.switchRole(to: .provider)
        }
    }

    func setupBindings() {
        viewModel.onUserDataUpdated = { [weak self] user in
            DispatchQueue.main.async {
                self?.nameLabel.text = user.name
                self?.usernameLabel.text = "@\(user.username)"
                
                // 📍 Displays "Bahrain" (default) OR updated Provider location
                self?.locationLabel.text = user.location
                
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
    }
}
