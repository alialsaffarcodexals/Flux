import UIKit

class ReportViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var reportedLabel: UILabel!
    @IBOutlet weak var reporterLabel: UILabel!
    @IBOutlet weak var reportDescription: UILabel!
    @IBOutlet weak var reportAnswer: UITextView!

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
        subjectLabel.text = "Scamming Activity"
        reportedLabel.text = "@cleanmax"
        reporterLabel.text = "@suefgwi"

        reportDescription.text =
        """
        Received multiple scam messages today offering fake rewards.
        User is trying to phish account details.
        Please investigate and ban.
        """
    }

    // MARK: - Answer TextView Setup
    private func setupAnswerTextView() {
        reportAnswer.text = ""
        reportAnswer.font = .systemFont(ofSize: 15)
        reportAnswer.layer.cornerRadius = 8
        reportAnswer.layer.borderWidth = 1
        reportAnswer.layer.borderColor = UIColor.systemGray4.cgColor
        reportAnswer.textContainerInset = UIEdgeInsets(
            top: 10,
            left: 8,
            bottom: 10,
            right: 8
        )
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
                    // fetch reporter and reported user display names
                    self?.viewModel?.fetchUser(userID: r.reporterId) { userResult in
                        DispatchQueue.main.async {
                            if case .success(let user) = userResult {
                                self?.reporterLabel.text = "@\(user.username)"
                            } else {
                                self?.reporterLabel.text = r.reporterId
                            }
                        }
                    }

                    self?.viewModel?.fetchUser(userID: r.reportedUserId) { userResult in
                        DispatchQueue.main.async {
                            if case .success(let user) = userResult {
                                self?.reportedLabel.text = "@\(user.username)"
                            } else {
                                self?.reportedLabel.text = r.reportedUserId
                            }
                        }
                    }

                case .failure(let error):
                    print("❌ Fetch report error:", error.localizedDescription)
                }
            }
        }
    }

    private func populate(with report: Report) {
        subjectLabel.text = report.reason
        reportDescription.text = report.description
    }

    @IBAction func markResolvedTapped(_ sender: Any) {
        guard let id = report?.id else { return }
        viewModel?.updateReportStatus(reportID: id, status: "Resolved") { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Update report error:", error.localizedDescription)
                } else {
                    print("✅ Report marked resolved")
                }
            }
        }
    }
}
