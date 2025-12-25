// File: Flux/Features/ProviderProfile/ViewContollers/ProviderMainProfileVC.swift

import UIKit

class ProviderMainProfileVC: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!        // Displays Business Name
    @IBOutlet weak var bioLabel: UILabel!         // Displays Bio
    @IBOutlet weak var locationLabel: UILabel!    // Displays Location
    @IBOutlet weak var profileImageView: UIImageView! // Shared Profile Image
    
    // Properties
    private var viewModel = ProviderProfileViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        // Fetch fresh data on load
        viewModel.fetchUserProfile()
    }
    
    func setupBindings() {
        viewModel.onUserDataUpdated = { [weak self] user in
            DispatchQueue.main.async {
                // 🏢 Logic: Show Business Name. Fallback to full name if empty.
                self?.nameLabel.text = user.businessName?.isEmpty == false ? user.businessName : user.name
                
                // 📝 Show Bio
                self?.bioLabel.text = user.bio ?? "No bio available."
                
                // 📍 Show Location (Shared Source)
                self?.locationLabel.text = user.location
                
                // 🖼️ Load Shared Profile Image
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

        viewModel.onError = {  error in
            print("Error: \(error)")
        }

        viewModel.onSwitchToBuyer = { [weak self] updatedUser in
            DispatchQueue.main.async {
                self?.performSwitchToSeekerProfile()
            }
        }
    }

    // MARK: - Actions
    @IBAction func seekerProfileTapped(_ sender: UIButton) {
        viewModel.didTapServiceSeekerProfile()
    }
    
    // MARK: - Navigation Logic
    private func performSwitchToSeekerProfile() {
        let storyboard = UIStoryboard(name: "SeekerProfile", bundle: nil)
        guard let seekerVC = storyboard.instantiateViewController(withIdentifier: "SeekerProfileViewController") as? SeekerProfileViewController else { return }

        if let nav = self.navigationController {
            var viewControllers = nav.viewControllers
            viewControllers.removeAll { $0 === self }
            viewControllers.append(seekerVC)
            nav.setViewControllers(viewControllers, animated: true)
        }
    }
}
