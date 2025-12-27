// File: Flux/Features/ProviderProfile/ViewContollers/ProviderMainProfileVC.swift

import UIKit
import FirebaseAuth

class ProviderMainProfileVC: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!        // Displays Business Name
    @IBOutlet weak var bioLabel: UILabel!         // Displays Bio
    @IBOutlet weak var locationLabel: UILabel!    // Displays Location
    @IBOutlet weak var profileImageView: UIImageView! // Shared Profile Image
    @IBOutlet weak var skillsTagContainer: UIStackView?
    
    // Properties
    private var viewModel = ProviderProfileViewModel()
    private var skills: [Skill] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        // Fetch fresh data on load
        viewModel.fetchUserProfile()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSkills()
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

        viewModel.onSkillsUpdated = { [weak self] skills in
            DispatchQueue.main.async {
                self?.skills = skills
                self?.updateSkillTags()
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

    private func refreshSkills() {
        guard let providerId = Auth.auth().currentUser?.uid else { return }
        viewModel.fetchSkills(providerId: providerId)
    }

    private func updateSkillTags() {
        guard let container = skillsTagContainer else { return }

        container.arrangedSubviews.forEach { view in
            container.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let names = skills.map { $0.name }
        let buttonsPerRow = 2
        var index = 0

        while index < names.count {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.alignment = .center

            for _ in 0..<buttonsPerRow {
                guard index < names.count else { break }
                let button = UIButton(type: .system)
                button.configuration = .tinted()
                button.configuration?.cornerStyle = .capsule
                button.setTitle(names[index], for: .normal)
                rowStack.addArrangedSubview(button)
                index += 1
            }

            container.addArrangedSubview(rowStack)
        }
    }
}
