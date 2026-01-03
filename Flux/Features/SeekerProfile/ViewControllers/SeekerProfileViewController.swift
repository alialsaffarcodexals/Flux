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
    @IBOutlet weak var historyCollectionView: UICollectionView!
    @IBOutlet weak var historyEmptyLabel: UILabel!
    @IBOutlet weak var favoritesEmptyLabel: UILabel!
    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    
    var viewModel = SeekerProfileViewModel()
    private let historyViewModel = HistoryVM()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Clear labels to prevent dummy text
        nameLabel.text = ""
        usernameLabel.text = ""
        locationLabel.text = ""
        phoneLabel.text = ""
        
        setupCollectionViews()
        setupBindings()
        //  Fetch fresh data every time the view loads to ensure sync with Provider updates
        viewModel.fetchUserProfile()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        historyViewModel.loadHistory()
    }
    
    private func setupCollectionViews() {
        historyCollectionView.dataSource = self
        historyCollectionView.delegate = self
        historyEmptyLabel.isHidden = true
        favoritesEmptyLabel.isHidden = true
        favoritesCollectionView.dataSource = self
        favoritesCollectionView.delegate = self
    }
    
    //  FIX 1: Do not switch tabs directly. Ask the ViewModel.
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
        print("Settings Tapped in Seeker Profile")
        
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        
        guard let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else {
            print("Error: Could not find 'SettingsViewController' in Settings.storyboard")
            return
        }
        
        // Push onto existing navigation stack (preserves Back button)
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    //  Edit Profile Picture Action
    @IBAction func editProfilePictureTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }

    @IBAction func editInterestsTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Intersets", bundle: nil)
        if let interestsVC = storyboard.instantiateViewController(withIdentifier: "InstersetsVC") as? InterestsViewController {
            navigationController?.pushViewController(interestsVC, animated: true)
        } else {
             print("Error: Could not instantiate InterestsViewController")
        }
    }

    func setupBindings() {
        viewModel.onUserDataUpdated = { [weak self] user in
            DispatchQueue.main.async {
                self?.nameLabel.text = user.name
                self?.usernameLabel.text = "@\(user.username)"
                
                //  Displays "Bahrain" (default) OR updated Provider location
                self?.locationLabel.text = user.location
                
                // Safety: Optional chain phoneLabel in case it's not connected
                self?.phoneLabel?.text = user.phoneNumber ?? "Not set"
                
                //  Always show seeker profile image in seeker profile
                if let imageURL = user.profileImageURL(for: .buyerMode), !imageURL.isEmpty, let url = URL(string: imageURL) {
                    // Load image asynchronously
                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self?.profileImageView.image = image
                            }
                        }
                    }
                } else {
                     // Keep default or placeholder
                }
                
                //  Dynamic Interests
                self?.updateInterests(with: user.interests)
            }
        }
        
        viewModel.onFavoritesUpdated = { [weak self] favorites in
            DispatchQueue.main.async {
                let isEmpty = favorites.isEmpty
                self?.favoritesEmptyLabel.isHidden = !isEmpty
                self?.favoritesCollectionView.reloadData()
            }
        }

        historyViewModel.onDataChanged = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.historyCollectionView.reloadData()
                let isEmpty = self.historyViewModel.itemCount == 0
                self.historyEmptyLabel.isHidden = !isEmpty
            }
        }

        historyViewModel.onError = { error in
            print("Error fetching history: \(error.localizedDescription)")
        }
        
        //  FIX 2: Handle the navigation to the Intro VC
        viewModel.onNavigateToProviderSetup = { [weak self] in
            let storyboard = UIStoryboard(name: "ProviderProfile", bundle: nil)
            
            // Instantiate the Intro VC using the ID you provided
            if let introVC = storyboard.instantiateViewController(withIdentifier: "ProviderIntroViewController") as? ProviderIntroViewController {
                
                // Hide bottom bar so the user focuses on the setup flow
                introVC.hidesBottomBarWhenPushed = true
                
                self?.navigationController?.pushViewController(introVC, animated: true)
            } else {
                print("Error: Could not find 'ProviderIntroViewController'")
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
        
        // 1. Clear existing subviews
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
        
        // 3. Populate Interests using a "Tag Cloud" approach
        // Since UIStackView doesn't wrap, we build horizontal rows dynamically.
        
        let containerWidth = stackView.frame.width > 0 ? stackView.frame.width : (UIScreen.main.bounds.width - 32)
        var currentRowStack = createRowStack()
        stackView.addArrangedSubview(currentRowStack)
        
        // Add a flexible spacer to the first row (will be moved if row fills up)
        var currentSpacer = UIView()
        // Determine layout
        
        // Need to calculate cumulative width
        var currentWidth: CGFloat = 0
        let spacing: CGFloat = 10
        
        let displayInterests: [String]
        if interests.count > 4 {
            displayInterests = Array(interests.prefix(4)) + ["..."]
        } else {
            displayInterests = interests
        }

        for interest in displayInterests {
            let button = createInterestButton(title: interest)
            let buttonWidth = button.intrinsicContentSize.width
            
            // Check if button fits in current row
            if currentWidth + buttonWidth + spacing > containerWidth {
                // Must add a spacer to the END of the previous row to force left alignment
                currentRowStack.addArrangedSubview(UIView()) // Flexible spacer to fill gap
                
                // Start a new row
                currentRowStack = createRowStack()
                stackView.addArrangedSubview(currentRowStack)
                currentWidth = 0
            }
            
            currentRowStack.addArrangedSubview(button)
            currentWidth += buttonWidth + spacing
        }
        
        // Add final spacer to the last row to ensure left alignment
        currentRowStack.addArrangedSubview(UIView())
    }
    
    private func createRowStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill // Important for left alignment with spacer
        stack.alignment = .fill
        stack.spacing = 10
        return stack
    }
    
    private func createInterestButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.label, for: .normal)
        // Use configuration for padding and style
        var config = UIButton.Configuration.tinted()
        config.baseForegroundColor = UIColor(named: "BlueButtons") ?? .systemBlue
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 19, bottom: 4, trailing: 19)
        config.cornerStyle = .capsule
        config.buttonSize = .medium
        
        let displayTitle = title.count > 10 ? String(title.prefix(10)) + "..." : title
        config.title = displayTitle
        config.titleLineBreakMode = .byTruncatingTail
        
        button.configuration = config
        button.isUserInteractionEnabled = false

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 27)
        ])
        
        // Force calculation of efficient size for layout logic
        // We need to layout carefully
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }
}

// MARK: - UICollectionViewDataSource
extension SeekerProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == historyCollectionView {
            return historyViewModel.itemCount
        } else if collectionView == favoritesCollectionView {
            return viewModel.favoriteProviders.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceCell", for: indexPath) as? ServiceCardCell else {
            return UICollectionViewCell()
        }
        
        if collectionView == historyCollectionView, let item = historyViewModel.item(at: indexPath.item) {
            cell.titleLabel.text = item.serviceName

            let imageURL = item.booking.coverImageURLAtBooking ?? item.profileImageURL
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                cell.mainImageView.image = UIImage(systemName: "doc.text.image")
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.mainImageView.image = image
                        }
                    }
                }
            } else {
                cell.mainImageView.image = UIImage(systemName: "doc.text.image")
            }

            cell.actionButton.isHidden = true
            return cell
        }

        let provider = viewModel.favoriteProviders[indexPath.item]
        cell.titleLabel.text = provider.businessName ?? provider.name
        
        // Load image
        let imageURL = provider.profileImageURL(for: .sellerMode) ?? provider.profileImageURL(for: .buyerMode)
        if let imageURL = imageURL, let url = URL(string: imageURL) {
            cell.mainImageView.image = UIImage(systemName: "person.circle.fill")
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        cell.mainImageView.image = image
                    }
                }
            }
        } else {
            cell.mainImageView.image = UIImage(systemName: "person.circle.fill")
        }

        // Hide action button for read-only view
        cell.actionButton.isHidden = true
        
        return cell
    }
}

// MARK: - UIImagePickerControllerDelegate
extension SeekerProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let editedImage = info[.editedImage] as? UIImage {
            print("Image selected for Seeker profile")
            // Optimistic UI update
            profileImageView.image = editedImage
            // Upload and save
            viewModel.updateSeekerProfileImage(image: editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            print("Image selected for Seeker profile")
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
