import UIKit

class ViewNotificationViewController: UIViewController {

    // MARK: - Data
    var notification: Notification!

    // MARK: - Outlets
    @IBOutlet weak var deliveredFrom: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var detailsTextView: UITextView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    // MARK: - UI
    private func configureUI() {
        guard notification != nil else { return }

        deliveredFrom.text = notification.fromName
        detailsTextView.text = notification.message
        detailsTextView.isEditable = false

        let formatter = DateFormatter()

        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        dateLabel.text = formatter.string(from: notification.createdAt)

        formatter.dateStyle = .none
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: notification.createdAt)
    }
}
