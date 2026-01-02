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
    
    var skillID: String?
    var skill: Skill?
    var viewModel: AdminToolsViewModel?
    // Desired image display size for provider/profile and proof images
    private let imageDisplaySize = CGSize(width: 88, height: 88)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup default placeholders and styling early so IBOutlets render correctly
        let placeholderProvider = UIImage(systemName: "person.crop.circle.fill")
        ProviderPhoto.contentMode = .scaleAspectFill
        ProviderPhoto.clipsToBounds = true
        ProviderPhoto.image = placeholderProvider

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
                                    strong.setImage(from: user.providerProfileImageURL, into: strong.ProviderPhoto, size: strong.imageDisplaySize)
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

        view.layoutIfNeeded()
    }

    // MARK: - Image helpers
    private func setImage(from urlString: String?, into imageView: UIImageView, size: CGSize) {
        guard let s = urlString, let url = URL(string: s) else {
            DispatchQueue.main.async {
                // keep existing image (placeholder) and log missing URL
                print("⚠️ SkillViewController: no URL for imageView \(imageView) — leaving placeholder")
            }
            return
        }

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("⚠️ SkillViewController: image download error for \(url): \(error.localizedDescription)")
                return
            }
            guard let data = data, let img = UIImage(data: data) else {
                print("⚠️ SkillViewController: image data invalid for \(url)")
                return
            }
            DispatchQueue.main.async {
                imageView.image = img
                print("✅ SkillViewController: loaded image for \(url)")
            }
        }.resume()
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
        // Proof files have been removed from the skill UI.
        let a = UIAlertController(title: "Removed", message: "Proof files are no longer attached to skills.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
