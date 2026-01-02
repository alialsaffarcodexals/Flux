import UIKit
import FirebaseFirestore

class ViewNotificationViewController: UIViewController {

    // MARK: - Data
    var notification: Notification!

    // MARK: - Outlets
    @IBOutlet weak var NotificationTitle: UILabel!
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
        // Title depending on type
        self.title = notification.type == .activity ? "View Activity" : "View Notification"

        // Delivered from: prefer `fromName`, but if missing or generic try to resolve user document
        let name = notification.fromName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty || name == "User" || name == "System" {
            if let fromId = notification.fromUserId, !fromId.isEmpty {
                let usersRef = Firestore.firestore().collection("users").document(fromId)
                usersRef.getDocument { [weak self] snap, _ in
                    guard let self = self else { return }
                    if let data = snap?.data() {
                        let display = (data["displayName"] as? String) ?? (data["username"] as? String) ?? (data["email"] as? String) ?? "User"
                        DispatchQueue.main.async {
                            self.deliveredFrom.text = display
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.deliveredFrom.text = "User"
                        }
                    }
                }
            } else {
                deliveredFrom.text = name.isEmpty ? "User" : name
            }
        } else {
            deliveredFrom.text = name
        }

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
