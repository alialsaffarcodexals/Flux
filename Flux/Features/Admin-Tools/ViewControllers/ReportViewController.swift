import UIKit

class ReportViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var reportedLabel: UILabel!
    @IBOutlet weak var reporterLabel: UILabel!
    @IBOutlet weak var reportDescription: UILabel!
    @IBOutlet weak var reportAnswer: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDummyData()
        setupAnswerTextView()
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
}
