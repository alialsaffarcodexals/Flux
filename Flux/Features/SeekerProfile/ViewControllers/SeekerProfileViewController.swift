// File: Flux/Features/SeekerProfile/Storyboards/SeekerProfileViewController.swift

import UIKit

class SeekerProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    @IBOutlet weak var providerProfileButton: UIButton!
    @IBOutlet weak var interestsStackView: UIStackView!
    
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var favoritesButton: UIButton!
    
    var viewModel = SeekerProfileViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 🧹 Clear labels to prevent dummy text
        nameLabel.text = ""
        usernameLabel.text = ""
        locationLabel.text = ""
        phoneLabel.text = ""
        
        setupBindings()
        // 🚀 Fetch fresh data every time the view loads to ensure sync with Provider updates
        viewModel.fetchUserProfile()
    }
    
    // ✅ FIX 1: Do not switch tabs directly. Ask the ViewModel.
    @IBAction func providerProfileTapped(_ sender: UIButton) {
        viewModel.didTapServiceProviderProfile()
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
    
    // ✅ Edit Profile Picture Action
    @IBAction func editProfilePictureTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
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
                
                // ✅ Display Seeker profile image
                // Only load image if URL exists and is not empty - otherwise keep storyboard placeholder
                if let imageURL = user.seekerProfileImageURL,
                   !imageURL.isEmpty,
                   let url = URL(string: imageURL) {
                    // Load image asynchronously
                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url) {
                            DispatchQueue.main.async {
                                self?.profileImageView.image = UIImage(data: data)
                            }
                        }
                        // If loading fails, do nothing - keep existing image (storyboard placeholder)
                    }
                }
                // If URL is nil/empty, do nothing - storyboard placeholder remains
                
                // 🎨 Dynamic Interests
                self?.updateInterests(with: user.interests)
            }
        }
        
        // ✅ FIX 2: Handle the navigation to the Intro VC
        viewModel.onNavigateToProviderSetup = { [weak self] in
            let storyboard = UIStoryboard(name: "ProviderProfile", bundle: nil)
            
            // Instantiate the Intro VC using the ID you provided
            if let introVC = storyboard.instantiateViewController(withIdentifier: "ProviderIntroViewController") as? ProviderIntroViewController {
                
                // Hide bottom bar so the user focuses on the setup flow
                introVC.hidesBottomBarWhenPushed = true
                
                self?.navigationController?.pushViewController(introVC, animated: true)
            } else {
                print("🔴 Error: Could not find 'ProviderIntroViewController'")
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
    
    private func updateInterests(with interests: [String]?) {
        guard let stackView = interestsStackView else { return }
        
        // 1. Clear existing subviews (placeholders)
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 2. Handle Empty State
        guard let interests = interests, !interests.isEmpty else {
            let label = UILabel()
            label.text = "You haven't added any interests yet."
            label.textColor = .secondaryLabel
            label.font = .systemFont(ofSize: 18)
            label.numberOfLines = 0
            stackView.addArrangedSubview(label)
            return
        }
        
        // 3. Populate Interests
        // We'll organize them into rows if needed, or just add them to the vertical stack 
        // assuming the stack view handles layout or is vertical. 
        // Based on "My Skills" reference, usually we want a flow layout or horizontal rows.
        // For simplicity and robustness if I don't control the layout class, I'll add them as buttons/labels.
        // If the stack view is Vertical, I should wrap them in horizontal stacks (Rows).
        
        // Check if we need rows (simple logic: 2 items per row or flow)
        // Let's assume a simple vertical list of rows for now to be safe, or just add them if it's horizontal.
        // Analyzing "SkillDetails" usually implies a flow or grid.
        // Let's try to infer from the requested "Provider Profile My Skills" template.
        // Since I can't see ProviderProfile code easily right now without checking, I'll implement a safe Row-based approach.
        
        let chunkSize = 3 // Items per row
        let chunks = stride(from: 0, to: interests.count, by: chunkSize).map {
            Array(interests[$0..<min($0 + chunkSize, interests.count)])
        }
        
        for chunk in chunks {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually // Or fill
            rowStack.spacing = 10
            rowStack.alignment = .leading
            
            for interest in chunk {
                let button = UIButton(type: .system)
                button.setTitle(interest, for: .normal)
                button.setTitleColor(.label, for: .normal)
                button.backgroundColor = .systemGray5
                button.layer.cornerRadius = 16
                button.clipsToBounds = true
                button.isUserInteractionEnabled = false // Static tag
                
                // Add padding via configuration
                var config = UIButton.Configuration.filled()
                config.baseBackgroundColor = .systemGray5
                config.baseForegroundColor = .label
                config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                config.cornerStyle = .capsule
                button.configuration = config
                
                rowStack.addArrangedSubview(button)
            }
            
            // Add spacer if row is not full to left align? 
            // Distribution fillEqually might stretch. Let's use 'fill' and header alignment.
             if chunk.count < chunkSize {
                 let spacer = UIView()
                 rowStack.addArrangedSubview(spacer)
                 // Make spacer take remaining width if distribution is fill
                 // But wait, horizontal stack with alignment leading/fill usually packs left.
             }

            stackView.addArrangedSubview(rowStack)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension SeekerProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let editedImage = info[.editedImage] as? UIImage {
            print("📸 Image selected for Seeker profile")
            // Optimistic UI update
            profileImageView.image = editedImage
            // Upload and save
            viewModel.updateSeekerProfileImage(image: editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            print("📸 Image selected for Seeker profile")
            // Optimistic UI update
            profileImageView.image = originalImage
            // Upload and save
            viewModel.updateSeekerProfileImage(image: originalImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
