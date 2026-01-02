// File: Flux/Features/ProviderProfile/ViewContollers/ProviderMainProfileVC.swift

import UIKit
import FirebaseAuth

class ProviderMainProfileVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!        // Displays Business Name
    @IBOutlet weak var bioLabel: UILabel!         // Displays Bio
    @IBOutlet weak var locationLabel: UILabel!    // Displays Location
    @IBOutlet weak var phoneLabel: UILabel!
    
    @IBOutlet weak var profileImageView: UIImageView! // Shared Profile Image
    @IBOutlet weak var skillsTagContainer: UIStackView?
    @IBOutlet weak var skillsRowOneStackView: UIStackView?
    @IBOutlet weak var skillsRowTwoStackView: UIStackView?
    @IBOutlet weak var skillsRowTwoSpacerView: UIView?
    @IBOutlet weak var skillTagButtonOne: UIButton?
    @IBOutlet weak var skillTagButtonTwo: UIButton?
    @IBOutlet weak var skillTagButtonThree: UIButton?
    @IBOutlet weak var skillTagButtonFour: UIButton?
    @IBOutlet weak var skillTagMoreButton: UIButton?
    
    @IBOutlet weak var editPortfolioButton: UIButton!
    
    // Properties
    private var viewModel = ProviderProfileViewModel()
    private var skills: [Skill] = []
    private var emptySkillsLabel: UILabel?
    // Keep original full titles for truncation/restore
    private var originalTagTitles: [ObjectIdentifier: String] = [:]
    // Base padding used for tag buttons (left/right)
    private let tagBaseHorizontalPadding: CGFloat = 19.0
    // Maximum extra padding per side when distributing remaining space
    private let tagMaxExtraPerSide: CGFloat = 20.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 🧹 Clear labels to prevent dummy text
        nameLabel.text = ""
        bioLabel.text = ""
        locationLabel.text = ""
        phoneLabel.text = ""
        
        setupBindings()
        resetSkillTagUI()
        removeWidthConstraints()
        // Fetch fresh data on load
        viewModel.fetchUserProfile()
    }
    
    // MARK: - Layout Fix Helper
    private func removeWidthConstraints() {
        let buttons = [skillTagButtonOne, skillTagButtonTwo, skillTagButtonThree, skillTagButtonFour]
        
        buttons.forEach { button in
            guard let btn = button else { return }
            // Iterate through constraints affecting the button and disable width constraints
            btn.constraints.forEach { constraint in
                if constraint.firstAttribute == .width && constraint.relation == .equal {
                    constraint.isActive = false
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSkills()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSpacerVisibility()
        updateTagLayout()
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
                
                // Safety: Optional chain phoneLabel in case it's not connected
                self?.phoneLabel?.text = user.phoneNumber ?? "Not set"
                
                // ✅ Display Provider profile image
                // Only load image if URL exists and is not empty - otherwise keep storyboard placeholder
                if let imageURL = user.providerProfileImageURL,
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
        
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.showLoadingIndicator()
                } else {
                    self?.hideLoadingIndicator()
                }
            }
        }
        
//        viewModel.onSwitchToBuyer = { [weak self] updatedUser in
//            DispatchQueue.main.async {
//                self?.navigateToSeekerProfile()
//            }
//        }
    }
    
    // MARK: - Actions
    @IBAction func seekerProfileTapped(_ sender: UIButton) {
        // viewModel.didTapServiceSeekerProfile()
        navigateToSeekerProfile()
    }
    
    @IBAction func settingsTapped(_ sender: Any) {
        print("⚙️ Settings Tapped in Provider Profile")
        
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        
        guard let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else {
            print("🔴 Error: Could not find 'SettingsViewController' in Settings.storyboard")
            return
        }
        
        // Push onto existing navigation stack (preserves Back button)
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    @IBAction func editPortfolioTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Portfolio", bundle: nil)

        guard let portfolioVC = storyboard.instantiateViewController(withIdentifier: "PortfolioVC") as? PortfolioListViewController else {
            assertionFailure("PortfolioVC in Portfolio.storyboard is not PortfolioListViewController. Check storyboard Class/Module.")
            return
        }

        navigationController?.pushViewController(portfolioVC, animated: true)
    }
    
    // MARK: - Service Packages
    @IBAction func viewServicePackagesTapped(_ sender: Any) {
        if let vc = AppNavigator.shared.getServicePackagesListViewController() {
            navigationController?.pushViewController(vc, animated: true)
        } else {
            print("🔴 Error: Could not instantiate ServicePackagesListViewController via AppNavigator")
        }
    }
    
    // ✅ Edit Provider Profile Picture Action
    @IBAction func editProviderProfilePictureTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }

    
    // MARK: - Navigation Logic
    private func navigateToSeekerProfile() {
        if let tabBarController = self.tabBarController as? MainTabBarController {
             tabBarController.switchRole(to: .seeker)
        }
    }
    
    private func refreshSkills() {
        guard let providerId = Auth.auth().currentUser?.uid else { return }
        viewModel.fetchSkills(providerId: providerId)
    }
    
    private func updateSkillTags() {
        let verifiedSkills = skills
            .filter { $0.status == .approved }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        applySkillTags(skillNames: verifiedSkills.map { $0.name })
    }
    
    private func resetSkillTagUI() {
        clearTagButton(skillTagButtonOne)
        clearTagButton(skillTagButtonTwo)
        clearTagButton(skillTagButtonThree)
        clearTagButton(skillTagButtonFour)
        clearTagButton(skillTagMoreButton)
        skillsRowOneStackView?.isHidden = true
        skillsRowTwoStackView?.isHidden = true
        skillsRowTwoSpacerView?.isHidden = true
        emptySkillsLabel?.isHidden = true
    }
    
    private func applySkillTags(skillNames: [String]) {
        resetSkillTagUI()
        
        guard !skillNames.isEmpty else {
            showEmptySkillsLabel()
            return
        }
        
        hideEmptySkillsLabel()
        
        let count = min(skillNames.count, 4)
        let hasMore = skillNames.count > 4
        
        if count >= 1 {
            setTagButton(skillTagButtonOne, title: skillNames[0])
        }
        if count >= 2 {
            setTagButton(skillTagButtonTwo, title: skillNames[1])
        }
        
        if count <= 2 {
            skillsRowOneStackView?.isHidden = false
            skillsRowTwoStackView?.isHidden = true
            skillsRowTwoSpacerView?.isHidden = true
            return
        }
        
        skillsRowOneStackView?.isHidden = false
        skillsRowTwoStackView?.isHidden = false
        
        if count >= 3 {
            setTagButton(skillTagButtonThree, title: skillNames[2])
        }
        if count >= 4 {
            setTagButton(skillTagButtonFour, title: skillNames[3])
        }
        
        if hasMore {
            setTagButton(skillTagMoreButton, title: "...")
        }
        
        // Let the layout update, then adjust padding/truncation
        updateSpacerVisibility()
        updateTagLayout()
    }
    
    // MARK: - Updated Tag Logic
    // MARK: - Updated Tag Logic
    private func setTagButton(_ button: UIButton?, title: String) {
        guard let button = button else { return }
        originalTagTitles[ObjectIdentifier(button)] = title
        
        // Logic: Only truncate if text is actually long (> 10 chars)
        let displayTitle = title.count > 10 ? String(title.prefix(10)) + "..." : title
        
        // Visual Setup
        button.isHidden = false
        button.isUserInteractionEnabled = false
        
        // FIX STARTS HERE: Use Configuration for Title and Line Break Mode
        var config = button.configuration ?? UIButton.Configuration.filled()
        
        config.title = displayTitle // Set title on config directly
        config.titleLineBreakMode = .byTruncatingTail // FORCE single line
        
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 4,
            leading: tagBaseHorizontalPadding,
            bottom: 4,
            trailing: tagBaseHorizontalPadding
        )
        button.configuration = config
        // FIX ENDS HERE
    }
    
    private func clearTagButton(_ button: UIButton?) {
        guard let button = button else { return }
        var config = button.configuration ?? UIButton.Configuration.filled()
        config.title = ""
        config.titleLineBreakMode = .byTruncatingTail
        button.configuration = config
        button.isHidden = true
        button.isUserInteractionEnabled = false
    }
    
    private func showEmptySkillsLabel() {
        guard let container = skillsTagContainer else { return }
        let label = emptySkillsLabel ?? {
            let label = UILabel()
            label.text = "You don't have any skill yet"
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            label.textAlignment = .left
            label.font = .systemFont(ofSize: 18)
            emptySkillsLabel = label
            return label
        }()
        
        if label.superview == nil {
            container.addArrangedSubview(label)
        }
        label.isHidden = false
    }
    
    private func hideEmptySkillsLabel() {
        emptySkillsLabel?.isHidden = true
    }
    
    private func updateSpacerVisibility() {
        guard let spacer = skillsRowTwoSpacerView,
              let rowTwo = skillsRowTwoStackView,
              !rowTwo.isHidden else {
            skillsRowTwoSpacerView?.isHidden = true
            return
        }
        
        view.layoutIfNeeded()
        
        let visibleButtons = [skillTagButtonThree, skillTagButtonFour, skillTagMoreButton]
            .compactMap { $0 }
            .filter { !$0.isHidden }
        
        if visibleButtons.isEmpty {
            spacer.isHidden = true
            return
        }
        
        let hasLongText = visibleButtons.contains { button in
            let title = button.title(for: .normal) ?? ""
            return title.count > 10
        }
        
        let totalSpacing = rowTwo.spacing * CGFloat(max(visibleButtons.count - 1, 0))
        let totalWidth = visibleButtons.reduce(0) { $0 + $1.intrinsicContentSize.width } + totalSpacing
        let availableWidth = rowTwo.bounds.width
        let isTight = availableWidth > 0 && totalWidth >= availableWidth * 0.92
        
        spacer.isHidden = hasLongText || isTight
    }
    
    // MARK: - Tag layout helpers (dynamic padding and truncation)
    private func updateTagLayout() {
        adjustTagsInRow(skillsRowOneStackView)
        adjustTagsInRow(skillsRowTwoStackView)
    }
    
    private func adjustTagsInRow(_ row: UIStackView?) {
        guard let row = row, !row.isHidden else { return }
        view.layoutIfNeeded()
        
        let visibleButtons = row.arrangedSubviews.compactMap { $0 as? UIButton }.filter { !$0.isHidden }
        guard !visibleButtons.isEmpty else { return }
        
        for btn in visibleButtons {
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.titleLabel?.numberOfLines = 1
            btn.titleLabel?.textAlignment = .center
            btn.contentHorizontalAlignment = .center
        }
        
        let spacing = row.spacing * CGFloat(max(visibleButtons.count - 1, 0))
        let availableWidth = row.bounds.width
        
        // Measure intrinsic widths
        var intrinsicWidths: [CGFloat] = []
        for btn in visibleButtons {
            let title = btn.configuration?.title ?? btn.title(for: .normal) ?? ""
            let font = btn.titleLabel?.font ?? UIFont.systemFont(ofSize: 14)
            let size = (title as NSString).size(withAttributes: [.font: font])
            let widthWithBasePadding = size.width + (tagBaseHorizontalPadding * 2)
            intrinsicWidths.append(widthWithBasePadding)
        }
        
        let totalIntrinsic = intrinsicWidths.reduce(0, +) + spacing
        
        if availableWidth > totalIntrinsic {
            // Distribute extra space as padding
            let remaining = availableWidth - totalIntrinsic
            let extraPerSide = min(max(remaining / CGFloat(visibleButtons.count * 2), 0), tagMaxExtraPerSide)
            
            for btn in visibleButtons {
                var config = btn.configuration ?? UIButton.Configuration.filled()
                config.contentInsets = NSDirectionalEdgeInsets(
                    top: 4,
                    leading: tagBaseHorizontalPadding + extraPerSide,
                    bottom: 4,
                    trailing: tagBaseHorizontalPadding + extraPerSide
                )
                config.titleLineBreakMode = .byTruncatingTail // ADD THIS LINE
                if let original = originalTagTitles[ObjectIdentifier(btn)] {
                    let displayTitle = original.count > 10 ? String(original.prefix(10)) + "..." : original
                    config.title = displayTitle
                }
                btn.configuration = config
            }
            return
        }
        
        // Not enough space - Reset to base padding
        for btn in visibleButtons {
            var config = btn.configuration ?? UIButton.Configuration.filled()
            
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 4,
                leading: tagBaseHorizontalPadding,
                bottom: 4,
                trailing: tagBaseHorizontalPadding
            )
            
            // FIX STARTS HERE: Update Config Title and Force Truncation
            config.titleLineBreakMode = .byTruncatingTail
            
            if let original = originalTagTitles[ObjectIdentifier(btn)] {
                let displayTitle = original.count > 10 ? String(original.prefix(10)) + "..." : original
                config.title = displayTitle // Update config title, not just btn.setTitle
            }
            
            btn.configuration = config
            // FIX ENDS HERE
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ProviderMainProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let editedImage = info[.editedImage] as? UIImage {
            print("📸 Image selected for Provider profile")
            // Optimistic UI update
            profileImageView.image = editedImage
            // Upload and save
            viewModel.updateProviderProfileImage(image: editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            print("📸 Image selected for Provider profile")
            // Optimistic UI update
            profileImageView.image = originalImage
            // Upload and save
            viewModel.updateProviderProfileImage(image: originalImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
