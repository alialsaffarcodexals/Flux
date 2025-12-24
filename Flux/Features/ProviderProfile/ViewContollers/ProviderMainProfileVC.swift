import UIKit

class ProviderMainProfileVC: UIViewController {

    // Properties
    private var viewModel = ProviderProfileViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        setupBindings()
        print("✅ Provider Profile Loaded")
    }
    
    func setupBindings() {
        // Handle Errors
        viewModel.onError = { [weak self] error in
            print("Error: \(error)")
            // Optional: Show an alert here
        }

        // Handle Mode Switch (The Fix)
        viewModel.onSwitchToBuyer = { [weak self] updatedUser in
            DispatchQueue.main.async {
                self?.performSwitchToSeekerProfile()
            }
        }
    }

    // MARK: - Actions
    @IBAction func seekerProfileTapped(_ sender: UIButton) {
        // Trigger the data update
        viewModel.didTapServiceSeekerProfile()
    }
    
    // MARK: - Navigation Logic
    private func performSwitchToSeekerProfile() {
        let storyboard = UIStoryboard(name: "SeekerProfile", bundle: nil)

        guard let seekerVC = storyboard.instantiateViewController(
            withIdentifier: "SeekerProfileViewController"
        ) as? SeekerProfileViewController else {
            assertionFailure("SeekerProfileViewController misconfigured in storyboard")
            return
        }

        if let nav = self.navigationController {
            var viewControllers = nav.viewControllers
            viewControllers.removeAll { $0 === self }
            viewControllers.append(seekerVC)
            nav.setViewControllers(viewControllers, animated: true)
        }
    }

}
