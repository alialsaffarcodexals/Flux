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

        // Listen to all notifications and filter client-side to include
        // user-targeted notifications and global/public notifications (toUserId == "all").
        db.collection("notifications")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Fetch notifications error:", error.localizedDescription)
                    return
                }

                let docs = snapshot?.documents ?? []

                var parsed: [Notification] = []

                for doc in docs {
                    let data = doc.data()

                    // tolerant parsing with reasonable defaults
                    let toId = data["toUserId"] as? String ?? "all"
                    let fromId = data["fromUserId"] as? String

                    // include documents that are targeted to this user, global, or originated from this user
                    if toId != userId && toId != "all" && fromId != userId { continue }

                    let id = doc.documentID
                    let title = data["title"] as? String ?? ""
                    let message = data["message"] as? String ?? ""
                    let typeString = data["type"] as? String ?? NotificationType.notification.rawValue
                    let type = NotificationType(rawValue: typeString) ?? .notification
                    let fromUserId = fromId
                    let fromName = data["fromName"] as? String ?? "System"

                    var createdAt = Date()
                    if let ts = data["createdAt"] as? Timestamp {
                        createdAt = ts.dateValue()
                    } else if let d = data["createdAt"] as? Date {
                        createdAt = d
                    }

                    let isRead = data["isRead"] as? Bool ?? false

                    let item = Notification(
                        id: id,
                        title: title,
                        message: message,
                        type: type,
                        fromUserId: fromUserId,
                        fromName: fromName,
                        toUserId: toId,
                        createdAt: createdAt,
                        isRead: isRead
                    )

                    parsed.append(item)
                }

                self.allNotifications = parsed
                // After fetching raw notifications, aggregate activities from other collections
                self.appendAggregatedActivities(for: userId, into: parsed) { merged in
                    // deduplicate by simple key
                    var seen = Set<String>()
                    let deduped = merged.filter { item in
                        let key = "\(item.type.rawValue)-\(item.fromUserId ?? "")-\(item.toUserId)-\(Int(item.createdAt.timeIntervalSince1970))"
                        if seen.contains(key) { return false }
                        seen.insert(key)
                        return true
                    }

                    self.allNotifications = deduped
                    self.filteredNotifications = deduped
                    self.onUpdate?()
                }
            }
    }


    // Aggregate activities from other collections (bookings, reviews) into Notification-like items
    private func appendAggregatedActivities(for userId: String, into base: [Notification], completion: @escaping ([Notification]) -> Void) {
        var results = base
        let group = DispatchGroup()

        // Recent bookings where user is the seeker (you did this)
        group.enter()
        db.collection("bookings")
            .whereField("seekerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments { snap, error in
                defer { group.leave() }
                guard let docs = snap?.documents, error == nil else { return }

                for doc in docs {
                    let d = doc.data()
                    let providerId = d["providerId"] as? String ?? ""
                    let serviceTitle = d["serviceTitle"] as? String ?? "Booking"
                    var createdAt = Date()
                    if let ts = d["createdAt"] as? Timestamp { createdAt = ts.dateValue() }
                    else if let s = d["createdAt"] as? Date { createdAt = s }

                    let note = d["note"] as? String ?? ""

                    let item = Notification(id: nil, title: "Booked: \(serviceTitle)", message: note, type: .activity, fromUserId: userId, fromName: "You", toUserId: providerId, createdAt: createdAt, isRead: false)
                    results.append(item)
                }
            }

        // Recent reviews by the user
        group.enter()
        db.collection("reviews")
            .whereField("seekerId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments { snap, error in
                defer { group.leave() }
                guard let docs = snap?.documents, error == nil else { return }

                for doc in docs {
                    let d = doc.data()
                    let providerId = d["providerId"] as? String ?? ""
                    let comment = d["comment"] as? String ?? ""
                    var createdAt = Date()
                    if let ts = d["timestamp"] as? Timestamp { createdAt = ts.dateValue() }
                    else if let s = d["timestamp"] as? Date { createdAt = s }

                    let item = Notification(id: nil, title: "Left a review", message: comment, type: .activity, fromUserId: userId, fromName: "You", toUserId: providerId, createdAt: createdAt, isRead: false)
                    results.append(item)
                }
            }

        // Recent skill submissions by other users (pending) - present them as notifications to the admin
        group.enter()
        db.collection("skills")
            .whereField("status", isEqualTo: SkillStatus.pending.rawValue)
            .limit(to: 30)
            .getDocuments { snap, error in
                defer { group.leave() }
                guard let docs = snap?.documents, error == nil else { return }

                for doc in docs {
                    let d = doc.data()
                    let providerId = d["providerId"] as? String ?? ""
                    // keep as admin-targeted notifications (skip adding as activity here)
                    if providerId == userId { continue }
                    let name = d["name"] as? String ?? "New Skill"
                    let description = d["description"] as? String ?? ""
                    let createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                    let item = Notification(id: nil, title: "Skill submission: \(name)", message: description, type: .notification, fromUserId: providerId, fromName: "User", toUserId: userId, createdAt: createdAt, isRead: false)
                    results.append(item)
                }
            }

        // Also include skills submitted by *this* user as activities (things the user did)
        group.enter()
        db.collection("skills")
            .whereField("providerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 30)
            .getDocuments { snap, error in
                defer { group.leave() }
                guard let docs = snap?.documents, error == nil else { return }

                for doc in docs {
                    let d = doc.data()
                    let name = d["name"] as? String ?? "Skill"
                    let createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let item = Notification(id: nil, title: "Submitted skill: \(name)", message: d["description"] as? String ?? "", type: .activity, fromUserId: userId, fromName: "You", toUserId: "all", createdAt: createdAt, isRead: false)
                    results.append(item)
                }
            }

        // Recent reports created by others - surface as notifications to admin
        group.enter()
        db.collection("reports")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments { snap, error in
                defer { group.leave() }
                guard let docs = snap?.documents, error == nil else { return }

                for doc in docs {
                    let d = doc.data()
                    func stringForKeys(_ keys: [String]) -> String? {
                        for k in keys {
                            if let v = d[k] as? String, !v.isEmpty { return v }
                        }
                        return nil
                    }

                    let reporterId = stringForKeys(["reporterId", "reporterID", "reporter"]) ?? ""

                    let reason = stringForKeys(["reason", "type", "title"]) ?? "Report"
                    var tsDate: Date = Date()
                    if let ts = d["timestamp"] as? Timestamp { tsDate = ts.dateValue() }
                    else if let num = d["timestamp"] as? Double { tsDate = Date(timeIntervalSince1970: num) }

                    // If the reporter is someone else, surface as admin notification
                    if reporterId != userId {
                        let item = Notification(id: nil, title: "New report: \(reason)", message: d["description"] as? String ?? "", type: .notification, fromUserId: reporterId, fromName: "User", toUserId: userId, createdAt: tsDate, isRead: false)
                        results.append(item)
                    } else {
                        // If the current user reported someone, include it in Activities
                        let item = Notification(id: nil, title: "Filed report: \(reason)", message: d["description"] as? String ?? "", type: .activity, fromUserId: userId, fromName: "You", toUserId: d["reportedUserId"] as? String ?? "", createdAt: tsDate, isRead: false)
                        results.append(item)
                    }
                }
            }

        group.notify(queue: .main) {
            completion(results.sorted(by: { $0.createdAt > $1.createdAt }))
        }
    }
    // MARK: - User initialization
    /// Ensure the current Firebase Auth user has a corresponding document in `users`.
    /// Creates or merges a minimal profile on first run so notifications/activities can be scoped.
    func ensureCurrentUserRecord(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let user = Auth.auth().currentUser else {
            let err = NSError(domain: "NotificationViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
            completion?(.failure(err))
            return
        }

        let usersRef = db.collection("users").document(user.uid)
        usersRef.getDocument { snapshot, error in
            if let error = error {
                completion?(.failure(error))
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                completion?(.success(()))
                return
            }

            var data: [String: Any] = [
                "uid": user.uid,
                "createdAt": FieldValue.serverTimestamp()
            ]

            if let email = user.email { data["email"] = email }
            if let name = user.displayName { data["displayName"] = name }
            if let url = user.photoURL?.absoluteString { data["photoURL"] = url }

            usersRef.setData(data, merge: true) { err in
                if let err = err {
                    completion?(.failure(err))
                } else {
                    // Create a starter notification for first-time users if they have no notifications
                    self.createWelcomeNotificationIfNeeded(for: user.uid, displayName: user.displayName)
                    completion?(.success(()))
                }
            }
        }
    }

    private func createWelcomeNotificationIfNeeded(for userId: String, displayName: String?) {
        // Check if the user already has notifications
        db.collection("notifications")
            .whereField("toUserId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments { [weak self] snap, error in
                guard let self = self else { return }
                if let _ = error { return }
                if let snap = snap, !snap.documents.isEmpty { return }

                // No notifications found - create a welcome notification
                    let docRef = self.db.collection("notifications").document()
                    let payload: [String: Any] = [
                        "title": "Welcome to Flux",
                        "message": "Hi \(displayName ?? "there") — you'll receive notifications and activity updates here.",
                        "type": NotificationType.notification.rawValue,
                        "fromName": "System",
                        "toUserId": userId,
                        "createdAt": FieldValue.serverTimestamp(),
                        "isRead": false
                    ]

                    docRef.setData(payload) { err in
                        if let err = err {
                            print("Create welcome notification error:", err.localizedDescription)
                        }
                    }
            }
    }

    // MARK: - Filter
    func filter(by type: NotificationType) {
        guard let userId = Auth.auth().currentUser?.uid else {
            filteredNotifications = []
            return
        }

        switch type {
        case .notification:
            // notifications: what others send to you (toUserId == you) or global
            filteredNotifications = allNotifications.filter { $0.type == .notification && ($0.toUserId == userId || $0.toUserId == "all") }
        case .activity:
            // activities: primarily what you did to others (fromUserId == you),
            // but also include activity broadcasts or activities targeted at you.
            filteredNotifications = allNotifications.filter { item in
                guard item.type == .activity else { return false }
                let fromMatches = item.fromUserId == userId
                let toMatches = item.toUserId == userId || item.toUserId == "all"
                return fromMatches || toMatches
            }
        }
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
