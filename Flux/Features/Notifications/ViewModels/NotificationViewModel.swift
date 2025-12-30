import Foundation
import FirebaseFirestore
import FirebaseAuth

final class NotificationViewModel {

    private let db = Firestore.firestore()

    private(set) var allNotifications: [Notification] = []
    private(set) var filteredNotifications: [Notification] = []

    var onUpdate: (() -> Void)?

    // MARK: - Fetch
    func fetchNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("notifications")
            .whereField("toUserId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Fetch notifications error:", error.localizedDescription)
                    return
                }

                self.allNotifications = snapshot?.documents.compactMap {
                    try? $0.data(as: Notification.self)
                } ?? []

                self.filteredNotifications = self.allNotifications
                self.onUpdate?()
            }
    }

    // MARK: - Filter
    func filter(by type: NotificationType) {
        filteredNotifications = allNotifications.filter { $0.type == type }
        onUpdate?()
    }

    // MARK: - Read
    func markAsRead(_ notification: Notification) {
        guard let id = notification.id else { return }

        db.collection("notifications")
            .document(id)
            .updateData(["isRead": true])
    }

    // MARK: - Helpers
    func count() -> Int {
        filteredNotifications.count
    }

    func notification(at index: Int) -> Notification {
        filteredNotifications[index]
    }
}
