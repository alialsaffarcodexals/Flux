import UIKit

class SkillViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var providerName: UILabel!
    @IBOutlet weak var providerUserName: UILabel!
    @IBOutlet weak var skillName: UILabel!
    @IBOutlet weak var skillLevel: UILabel!
    @IBOutlet weak var approveButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    @IBOutlet weak var approveButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var rejectButtonHeight: NSLayoutConstraint!
    
    @IBOutlet weak var ProviderPhoto: UIImageView!
    
    @IBOutlet var SkillDescription: UILabel!
    
    @IBOutlet weak var ProofPhoto: UIImageView!
    @IBOutlet weak var DownloadProof: UIButton!
    
    var skillID: String?
    var skill: Skill?
    var viewModel: AdminToolsViewModel?
    // Desired image display size for provider/profile and proof images
    private let imageDisplaySize = CGSize(width: 88, height: 88)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup default placeholders and styling early so IBOutlets render correctly
        ProviderPhoto.contentMode = .scaleAspectFill
        ProviderPhoto.clipsToBounds = true
        if let placeholder = placeholderAvatar() {
            ProviderPhoto.image = placeholder
        }

        loadData()
    }

    // MARK: - Dummy Data (for testing UI)
    private func loadDummyData() {
        providerName.text = "Ali Mohammed"
        providerUserName.text = "@sdklfh95"
        skillName.text = "Advance Plumbing"
        skillLevel.text = "Expert"
    }

    private func loadData() {
        guard let id = skillID else {
            // if skill already provided, populate
            if let skill = skill {
                populate(with: skill)
            }
            return
        }

        viewModel?.fetchSkill(by: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let s):
                    self?.skill = s
                    self?.populate(with: s)
                    // also fetch provider name
                    self?.viewModel?.fetchUser(userID: s.providerId) { userResult in
                        DispatchQueue.main.async {
                            switch userResult {
                            case .success(let user):
                                if let strong = self {
                                    strong.providerName.text = user.name
                                    strong.providerUserName.text = "@\(user.username)"
                                    if let urlString = strong.preferredProfileImageURL(for: user) {
                                        strong.setImage(from: urlString, into: strong.ProviderPhoto, size: strong.imageDisplaySize)
                                    }
                                }
                            case .failure:
                                self?.providerName.text = s.providerId
                                self?.providerUserName.text = ""
                            }
                        }
                    }
                case .failure(let error):
                    print("❌ Fetch skill error:", error.localizedDescription)
                }
            }
        }
    }

    private func populate(with skill: Skill) {
        skillName.text = skill.name
        // Show the skill level (Beginner/Intermediate/Expert) rather than the approval status
        skillLevel.text = skill.level?.rawValue ?? "Unknown"
        // Adjust button heights based on skill status:
        // - Pending: keep normal height so admin can act
        // - Approved/Rejected: collapse buttons to height 0 so actions are hidden
        let isPending = (skill.status == .pending)
        approveButtonHeight?.constant = isPending ? 44 : 0
        rejectButtonHeight?.constant = isPending ? 44 : 0
        // Also hide the button views when collapsed so their titles don't remain visible
        approveButton?.isHidden = !isPending
        rejectButton?.isHidden = !isPending
        ProviderPhoto.contentMode = .scaleAspectFill
        ProviderPhoto.clipsToBounds = true

        // Show the skill description if available
        SkillDescription.text = skill.description ?? "No description provided."
        
        // Load and display proof image
        if let urlString = skill.proofImageURL, !urlString.isEmpty, let url = URL(string: urlString) {
            DownloadProof?.isEnabled = true
            DownloadProof?.setTitle("Download Proof", for: .normal)
            setImage(from: urlString, into: ProofPhoto, size: imageDisplaySize)
        } else {
            DownloadProof?.isEnabled = false
            DownloadProof?.setTitle("No Proof", for: .normal)
            ProofPhoto?.image = UIImage(named: "defaultPhoto") ?? UIImage(named: "placeholder")
            ProofPhoto?.contentMode = .scaleAspectFit
        }

        view.layoutIfNeeded()
    }

    // MARK: - Image helpers
    private func setImage(from urlString: String?, into imageView: UIImageView, size: CGSize) {
        guard let s = urlString, let url = URL(string: s) else {
            DispatchQueue.main.async {
                print("⚠️ SkillViewController: no URL for imageView \(imageView) — leaving placeholder")
            }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("⚠️ SkillViewController: image download error for \(url): \(error.localizedDescription)")
                return
            }
            guard let data = data, let downloaded = UIImage(data: data) else {
                print("⚠️ SkillViewController: image data invalid for \(url)")
                return
            }
            let thumb = self?.resizedImage(downloaded, to: size) ?? downloaded
            DispatchQueue.main.async {
                imageView.image = thumb
                imageView.layer.cornerRadius = min(size.width, size.height) / 2
                imageView.clipsToBounds = true
                print("✅ SkillViewController: loaded image for \(url)")
            }
        }.resume()
    }

    // Downscale avatar assets so they stay sharp without stretching.
    private func resizedImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func placeholderAvatar() -> UIImage? {
        guard let symbol = UIImage(systemName: "person.crop.circle.fill") else { return nil }
        let tinted = symbol.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
        return resizedImage(tinted, to: imageDisplaySize)
    }

    private func preferredProfileImageURL(for user: User) -> String? {
        if let mode = user.activeProfileMode, let url = user.profileImageURL(for: mode), !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return url
        }

        if user.role == .provider {
            return user.providerProfileImageURL ?? user.seekerProfileImageURL
        }

        return user.seekerProfileImageURL ?? user.providerProfileImageURL
    }

    // Ensure the provider photo is circular after layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ProviderPhoto.layer.cornerRadius = ProviderPhoto.frame.height / 2
        ProviderPhoto.clipsToBounds = true
    }

    @IBAction func approveTapped(_ sender: UIButton) {
        guard let skill = skill else { return }
        guard let id = skill.id, !id.isEmpty else {
            let a = UIAlertController(title: "Error", message: "Skill ID missing", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }

        // Ask for confirmation before approving
        let confirm = UIAlertController(title: "Approve Skill?", message: "Are you sure you want to approve this skill?", preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirm.addAction(UIAlertAction(title: "Approve", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.approveButton.isEnabled = false
            let loading = UIAlertController(title: nil, message: "Approving…", preferredStyle: .alert)
            self.present(loading, animated: true)
            self.viewModel?.updateSkillStatus(skillID: id, status: .approved) { [weak self] error in
                DispatchQueue.main.async {
                    loading.dismiss(animated: true) {
                        self?.approveButton.isEnabled = true
                        if let error = error {
                            let a = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            a.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(a, animated: true)
                        } else {
                            // Keep the displayed level unchanged after approving
                            self?.skillLevel.text = self?.skill?.level?.rawValue ?? "Unknown"
                            let a = UIAlertController(title: "Success", message: "Skill approved.", preferredStyle: .alert)
                            a.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                                if let nav = self?.navigationController {
                                    nav.popViewController(animated: true)
                                } else {
                                    self?.dismiss(animated: true, completion: nil)
                                }
                            })
                            self?.present(a, animated: true)
                        }
                    }
                }
            }
        })

        present(confirm, animated: true)
    }

    @IBAction func rejectTapped(_ sender: UIButton) {
        guard let skill = skill else { return }
        // present simple feedback alert
        let alert = UIAlertController(title: "Reject Skill", message: "Provide feedback (optional)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Feedback for provider" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            let feedback = alert.textFields?.first?.text
            guard let id = skill.id, !id.isEmpty else {
                let a = UIAlertController(title: "Error", message: "Skill ID missing", preferredStyle: .alert)
                a.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(a, animated: true)
                return
            }

            let loading = UIAlertController(title: nil, message: "Rejecting…", preferredStyle: .alert)
            self?.present(loading, animated: true)
            self?.viewModel?.updateSkillStatus(skillID: id, status: .rejected, adminFeedback: feedback) { error in
                DispatchQueue.main.async {
                    loading.dismiss(animated: true) {
                        if let error = error {
                            let a = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            a.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(a, animated: true)
                        } else {
                            // Keep the displayed level unchanged after rejecting
                            self?.skillLevel.text = self?.skill?.level?.rawValue ?? "Unknown"
                            let a = UIAlertController(title: "Success", message: "Skill rejected.", preferredStyle: .alert)
                            a.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                                if let nav = self?.navigationController {
                                    nav.popViewController(animated: true)
                                } else {
                                    self?.dismiss(animated: true, completion: nil)
                                }
                            })
                            self?.present(a, animated: true)
                        }
                    }
                }
            }
        })

        present(alert, animated: true)
    }

    @IBAction func downloadFileTapped(_ sender: UIButton) {
        guard let skillId = skill?.id else {
            let a = UIAlertController(title: "Error", message: "Skill ID not available", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }
        
        sender.isEnabled = false
        let loading = UIAlertController(title: nil, message: "Preparing download...", preferredStyle: .alert)
        present(loading, animated: true)
        
        // Fetch latest skill data from Firebase
        viewModel?.fetchSkill(by: skillId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let freshSkill):
                    guard let urlString = freshSkill.proofImageURL, !urlString.isEmpty else {
                        loading.dismiss(animated: true) {
                            sender.isEnabled = true
                            let a = UIAlertController(title: "No file", message: "No proof file available for this skill.", preferredStyle: .alert)
                            a.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(a, animated: true)
                        }
                        return
                    }
                    
                    print("🔍 Debug: Fetched URL from Firebase: \(urlString)")
                    
                    guard let validURL = URL(string: urlString) else {
                        loading.dismiss(animated: true) {
                            sender.isEnabled = true
                            print("❌ Failed to create URL from: \(urlString)")
                            let a = UIAlertController(title: "Error", message: "Invalid file URL", preferredStyle: .alert)
                            a.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(a, animated: true)
                        }
                        return
                    }
                    
                    print("✅ Valid URL created: \(validURL.absoluteString)")
                    
                    loading.message = "Downloading…"
                    
                    print("🚀 Starting download task...")
                    let task = URLSession.shared.downloadTask(with: validURL) { localURL, response, error in
                        print("📥 Download callback triggered")
                        print("   - localURL: \(String(describing: localURL))")
                        print("   - response: \(String(describing: response))")
                        print("   - error: \(String(describing: error))")
                        
                        DispatchQueue.main.async {
                            loading.dismiss(animated: true) {
                                sender.isEnabled = true
                                if let error = error {
                                    print("❌ Download error: \(error.localizedDescription)")
                                    let a = UIAlertController(title: "Download failed", message: error.localizedDescription, preferredStyle: .alert)
                                    a.addAction(UIAlertAction(title: "OK", style: .default))
                                    self?.present(a, animated: true)
                                    return
                                }

                                guard let localURL = localURL else {
                                    print("❌ No local URL returned")
                                    let a = UIAlertController(title: "Download failed", message: "No file returned.", preferredStyle: .alert)
                                    a.addAction(UIAlertAction(title: "OK", style: .default))
                                    self?.present(a, animated: true)
                                    return
                                }
                                
                                print("✅ File downloaded to: \(localURL.path)")

                                // Move to a temporary file with the original filename if possible
                                let fileName = validURL.lastPathComponent.isEmpty ? "prooffile" : validURL.lastPathComponent
                                let tmpDir = FileManager.default.temporaryDirectory
                                let destURL = tmpDir.appendingPathComponent(fileName)
                                
                                print("📂 Moving file to: \(destURL.path)")
                                
                                try? FileManager.default.removeItem(at: destURL)
                                do {
                                    try FileManager.default.moveItem(at: localURL, to: destURL)
                                    print("✅ File moved successfully")
                                } catch {
                                    print("⚠️ moveItem failed:", error.localizedDescription)
                                }

                                // Present share sheet so user can save or open the file
                                print("📤 Presenting share sheet")
                                let activity = UIActivityViewController(activityItems: [destURL], applicationActivities: nil)
                                activity.popoverPresentationController?.sourceView = sender
                                self?.present(activity, animated: true)
                            }
                        }
                    }
                    task.resume()
                    
                case .failure(let error):
                    loading.dismiss(animated: true) {
                        sender.isEnabled = true
                        print("❌ Failed to fetch skill: \(error.localizedDescription)")
                        let a = UIAlertController(title: "Error", message: "Failed to fetch skill data", preferredStyle: .alert)
                        a.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(a, animated: true)
                    }
                }
            }
        }
    }
}
