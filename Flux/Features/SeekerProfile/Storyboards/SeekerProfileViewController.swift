/// File: SeekerProfileViewController.swift.
/// Purpose: Class SeekerProfileViewController, func viewDidLoad, func setupBindings.
/// Location: Features/SeekerProfile/Storyboards/SeekerProfileViewController.swift.

import UIKit

/// Class SeekerProfileViewController: Responsible for the lifecycle, state, and behavior related to SeekerProfileViewController.
class SeekerProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    // Connect this Outlet to your "Service Provider Profile" button in Storyboard
        @IBOutlet weak var providerProfileButton: UIButton!
    
    var viewModel = SeekerProfileViewModel()

    /// Handles the view loading lifecycle.
    /// - Returns: Void
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings() 
        viewModel.fetchUserProfile() 
        
        // Set the location label text.
        locationLabel.text = "Bahrain 🇧🇭"
    }
    
    
    // Link this Action to your "Service Provider Profile" button in Storyboard
    @IBAction func providerProfileTapped(_ sender: UIButton) {
        viewModel.didTapServiceProviderProfile()
    }

    /// Sets up bindings between the view and the view model.
    /// - Returns: Void
    func setupBindings() {
        viewModel.onUserDataUpdated = { [weak self] user in
            DispatchQueue.main.async {
                self?.nameLabel.text = user.name
                self?.usernameLabel.text = "@\(user.username)"
                
                if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
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
                introVC.hidesBottomBarWhenPushed = true // Hide tab bar during setup
                self?.navigationController?.pushViewController(introVC, animated: true)
            }
        }
        
        
        
        viewModel.onError = { errorMessage in
            print("Error fetching profile: \(errorMessage)")
        }
        
    }
}
