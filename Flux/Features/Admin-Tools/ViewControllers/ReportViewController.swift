import UIKit

class ReportViewController: UIViewController, UITextViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var reportedLabel: UILabel!
    @IBOutlet weak var reporterLabel: UILabel!
    @IBOutlet weak var reportDescription: UILabel!
    @IBOutlet weak var reportAnswer: UITextView!
    
    @IBOutlet weak var reviewedButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var alterButtonHeight: NSLayoutConstraint!
    
    @IBOutlet weak var EvidencePhoto: UIImageView!
    @IBOutlet weak var DownloadEvidence: UIButton!
    
    var reportID: String?
    var report: Report?
    var viewModel: AdminToolsViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAnswerTextView()
        loadReport()
    }

    // MARK: - Dummy Data
    private func setupDummyData() {
        subjectLabel?.text = "Scamming Activity"
        reportedLabel?.text = "@cleanmax"
        reporterLabel?.text = "@suefgwi"

        reportDescription?.text =
        """
        Received multiple scam messages today offering fake rewards.
        User is trying to phish account details.
        Please investigate and ban.
        """
    }

    // MARK: - Answer TextView Setup
    private func setupAnswerTextView() {
        reportAnswer?.delegate = self
        reportAnswer?.font = .systemFont(ofSize: 15)
        reportAnswer?.layer.cornerRadius = 8
        reportAnswer?.layer.borderWidth = 1
        reportAnswer?.layer.borderColor = UIColor.systemGray4.cgColor
        reportAnswer?.textContainerInset = UIEdgeInsets(
            top: 10,
            left: 8,
            bottom: 10,
            right: 8
        )

        // Set placeholder text
        reportAnswer?.text = "Write your response..."
        reportAnswer?.textColor = .systemGray2
    }

    // MARK: - Answer helpers
    private var isAnswerValid: Bool {
        guard let text = reportAnswer?.text else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "Write your response..."
    }

    private func updateActionButtons() {
        let status = report?.status.lowercased() ?? ""
        // Adjust heights and visibility per status:
        // - "open": buttons visible and normal height
        // - "reviewed": buttons collapsed and hidden
        // - others: collapsed and hidden
        if status == "open" {
            reviewedButtonHeight?.constant = 44
            alterButtonHeight?.constant = 44
        } else {
            reviewedButtonHeight?.constant = 0
            alterButtonHeight?.constant = 0
        }

        // Hide the corresponding button views when collapsed so their titles don't remain visible.
        let shouldShow = (status == "open")
        let buttons = findButtonsByTitles(["Reviewed", "Alter"]) 
        buttons["Reviewed"]?.isHidden = !shouldShow
        buttons["Alter"]?.isHidden = !shouldShow

        view.layoutIfNeeded()
    }

    // Find buttons in the view hierarchy by their title (defensive: works without IBOutlets)
    private func findButtonsByTitles(_ titles: [String]) -> [String: UIButton] {
        var found: [String: UIButton] = [:]
        func search(in view: UIView) {
            for sub in view.subviews {
                if let b = sub as? UIButton, let t = b.configuration?.title ?? b.title(for: .normal) {
                    if titles.contains(t) { found[t] = b }
                }
                search(in: sub)
            }
        }
        search(in: self.view)
        return found
    }

    // MARK: - UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Write your response..." {
            textView.text = ""
            textView.textColor = .black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            textView.text = "Write your response..."
            textView.textColor = .systemGray2
        } else {
            textView.textColor = .black
        }
    }

    // MARK: - Load Report
    private func loadReport() {
        guard let id = reportID else { return }
        viewModel?.fetchReport(by: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let r):
                    self?.report = r
                    self?.populate(with: r)
                    // fetch reporter and reported user display names (tolerant lookup)
                    self?.viewModel?.fetchUserByIdentifier(r.reporterId) { userResult in
                        DispatchQueue.main.async {
                            if case .success(let user) = userResult {
                                self?.reporterLabel.text = "@\(user.username)"
                            } else {
                                self?.reporterLabel.text = r.reporterId
                            }
                        }
                    }

                    self?.viewModel?.fetchUserByIdentifier(r.reportedUserId) { userResult in
                        DispatchQueue.main.async {
                            if case .success(let user) = userResult {
                                self?.reportedLabel.text = "@\(user.username)"
                            } else {
                                self?.reportedLabel.text = r.reportedUserId
                            }
                        }
                    }

                case .failure(let error):
                    print("Fetch report error:", error.localizedDescription)
                }
            }
        }
    }

    private func populate(with report: Report) {
        subjectLabel?.text = report.reason
        reportDescription?.text = report.description
        // Show admin answer if present
        if let ans = report.answer, !ans.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reportAnswer?.text = ans
            // Keep admin answers readable by using a dark color (non-adaptive)
            reportAnswer?.textColor = .black
        }

        // Load and display evidence image
        if let urlString = report.evidenceImageURL, !urlString.isEmpty, let url = URL(string: urlString) {
            DownloadEvidence?.isEnabled = true
            DownloadEvidence?.setTitle("Download Evidence", for: .normal)
            loadImage(from: url, into: EvidencePhoto)
        } else {
            DownloadEvidence?.isEnabled = false
            DownloadEvidence?.setTitle("No Evidence", for: .normal)
            EvidencePhoto?.image = UIImage(named: "defaultPhoto") ?? UIImage(named: "placeholder")
            EvidencePhoto?.contentMode = .scaleAspectFit
        }

        // Make text view editable only when report is open
        let status = report.status.lowercased()
        reportAnswer?.isEditable = (status == "open")
        updateActionButtons()
    }

    @IBAction func markResolvedTapped(_ sender: Any) {
        guard let id = report?.id else { return }
        viewModel?.updateReportStatus(reportID: id, status: "Resolved") { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Update report error:", error.localizedDescription)
                } else {
                    print("Report marked resolved")
                }
            }
        }
    }

    @IBAction func reviewedTapped(_ sender: Any) {
        guard let id = report?.id else { return }
        let alert = UIAlertController(title: "Mark Reviewed", message: "Are you sure you want to mark this report as Reviewed?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
            // capture the admin answer (if any) and save it together with status
            let answerText = (self.reportAnswer?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let answerToSave: String? = (answerText.isEmpty || answerText == "Write your response...") ? nil : answerText

            self.viewModel?.updateReport(reportID: id, status: "Reviewed", answer: answerToSave) { error in
                DispatchQueue.main.async {
                    if let err = error {
                        self.presentError(err)
                    } else {
                        self.presentSuccess("Report marked Reviewed")
                        self.report?.status = "Reviewed"
                        if let a = answerToSave { self.report?.answer = a }
                        // Update UI then return to the reports list
                        self.populateIfNeeded()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            if let nav = self.navigationController {
                                nav.popViewController(animated: true)
                            } else {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    @IBAction func alterTapped(_ sender: Any) {
        guard let report = report else { return }
        let alert = UIAlertController(title: "Alter Report", message: "Edit reason or description", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Reason"; tf.text = report.reason }
        alert.addTextField { tf in tf.placeholder = "Description"; tf.text = report.description }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let reason = alert.textFields?.first?.text
            let desc = alert.textFields?.dropFirst().first?.text
            guard let id = report.id else { return }
            self.viewModel?.updateReport(reportID: id, reason: reason, description: desc) { error in
                DispatchQueue.main.async {
                    if let err = error {
                        self.presentError(err)
                    } else {
                        if let r = reason { self.report?.reason = r }
                        if let d = desc { self.report?.description = d }
                        self.presentSuccess("Report updated")
                        self.populateIfNeeded()
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - UI Helpers
    private func presentError(_ error: Error) {
        let a = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(a, animated: true)
    }

    private func presentSuccess(_ message: String) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(a, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { a.dismiss(animated: true) }
    }

    private func populateIfNeeded() {
        if let r = report { populate(with: r) }
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView?) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    imageView?.image = UIImage(named: "defaultPhoto") ?? UIImage(named: "placeholder")
                    imageView?.contentMode = .scaleAspectFit
                }
                return
            }
            DispatchQueue.main.async {
                imageView?.image = image
                imageView?.contentMode = .scaleAspectFill
            }
        }.resume()
    }
    
    @IBAction func downloadEvidenceTapped(_ sender: Any) {
        guard let reportId = report?.id else {
            presentError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Report ID not available"]))
            return
        }
        
        DownloadEvidence?.isEnabled = false
        let loading = UIAlertController(title: nil, message: "Preparing download...", preferredStyle: .alert)
        present(loading, animated: true)
        
        // Fetch latest report data from Firebase
        viewModel?.fetchReport(by: reportId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let freshReport):
                    guard let urlString = freshReport.evidenceImageURL, !urlString.isEmpty else {
                        loading.dismiss(animated: true) {
                            self?.DownloadEvidence?.isEnabled = true
                            self?.presentError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No evidence file available"]))
                        }
                        return
                    }
                    
                    print("🔍 Debug: Fetched URL from Firebase: \(urlString)")
                    
                    let cleanedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard let validURL = URL(string: cleanedString) else {
                        loading.dismiss(animated: true) {
                            self?.DownloadEvidence?.isEnabled = true
                            print("❌ Failed to create URL from: \(cleanedString)")
                            self?.presentError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid file URL"]))
                        }
                        return
                    }
                    
                    print("✅ Valid URL created: \(validURL.absoluteString)")
                    
                    loading.message = "Downloading…"
                    
                    self?.downloadEvidenceFile(from: validURL, sender: sender, loading: loading)
                    
                case .failure(let error):
                    loading.dismiss(animated: true) {
                        self?.DownloadEvidence?.isEnabled = true
                        print("❌ Failed to fetch report: \(error.localizedDescription)")
                        self?.presentError(error)
                    }
                }
            }
        }
    }
    
    private func downloadEvidenceFile(from validURL: URL, sender: Any, loading: UIAlertController) {
        print("🚀 Starting download task...")
        let task = URLSession.shared.downloadTask(with: validURL) { localURL, response, error in
            DispatchQueue.main.async {
                loading.dismiss(animated: true) {
                    self.DownloadEvidence?.isEnabled = true
                    if let error = error {
                        self.presentError(error)
                        return
                    }

                    guard let localURL = localURL else {
                        self.presentError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download failed: No file returned"]))
                        return
                    }

                    // Move to a temporary file with the original filename if possible
                    let fileName = validURL.lastPathComponent.isEmpty ? "evidencefile" : validURL.lastPathComponent
                    let tmpDir = FileManager.default.temporaryDirectory
                    let destURL = tmpDir.appendingPathComponent(fileName)
                    try? FileManager.default.removeItem(at: destURL)
                    do {
                        try FileManager.default.moveItem(at: localURL, to: destURL)
                    } catch {
                        print("⚠️ moveItem failed:", error.localizedDescription)
                    }

                    // Present share sheet so user can save or open the file
                    let activity = UIActivityViewController(activityItems: [destURL], applicationActivities: nil)
                    if let button = sender as? UIButton {
                        activity.popoverPresentationController?.sourceView = button
                    }
                    self.present(activity, animated: true)
                }
            }
        }
        task.resume()
    }
}
