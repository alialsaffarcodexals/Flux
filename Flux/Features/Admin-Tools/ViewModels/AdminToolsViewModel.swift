import Foundation
import FirebaseFirestore

class AdminToolsViewModel {

    var title: String {
        return "Admin Dashboard"
    }

    private let db = Firestore.firestore()

    // MARK: - Fetch Categories
    func fetchCategories(completion: @escaping (Result<[ServiceCategory], Error>) -> Void) {
        db.collection("serviceCategories")
            .order(by: "name")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let categories = snapshot?.documents.compactMap { doc -> ServiceCategory? in
                    let data = doc.data()
                    let id = doc.documentID
                    guard let name = data["name"] as? String else { return nil }
                    let iconURL = data["iconURL"] as? String
                    let isActive = data["isActive"] as? Bool ?? true
                    return ServiceCategory(id: id, name: name, iconURL: iconURL, isActive: isActive)
                } ?? []

                completion(.success(categories))
            }
    }

    // MARK: - Fetch Service Providers Count
    func fetchServiceProvidersCount(completion: @escaping (Result<Int, Error>) -> Void) {
        db.collection("users")
            .whereField("role", isEqualTo: "Provider")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let count = snapshot?.documents.count ?? 0
                completion(.success(count))
            }
    }

    // MARK: - Fetch Skills Stats
    func fetchSkillsStats(completion: @escaping (Result<(rejected: Int, pending: Int, approved: Int), Error>) -> Void) {
        db.collection("skills")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let docs = snapshot?.documents ?? []

                var rejected = 0
                var pending = 0
                var approved = 0

                for doc in docs {
                    let data = doc.data()
                    if let statusRaw = data["status"] as? String, let status = SkillStatus(rawValue: statusRaw) {
                        switch status {
                        case .rejected: rejected += 1
                        case .pending: pending += 1
                        case .approved: approved += 1
                        }
                    }
                }

                completion(.success((rejected: rejected, pending: pending, approved: approved)))
            }
    }

    // MARK: - Fetch Booking Stats
    func fetchBookingStats(completion: @escaping (Result<(rejected: Int, pending: Int, approved: Int), Error>) -> Void) {
        db.collection("bookings")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let docs = snapshot?.documents ?? []

                var rejected = 0
                var pending = 0
                var approved = 0

                for doc in docs {
                    let data = doc.data()
                    if let statusRaw = data["status"] as? String, let status = BookingStatus(rawValue: statusRaw) {
                        switch status {
                        case .rejected: rejected += 1
                        case .pending: pending += 1
                        case .accepted, .completed: approved += 1
                        default: break
                        }
                    }
                }

                completion(.success((rejected: rejected, pending: pending, approved: approved)))
            }
    }

    // MARK: - Fetch Skills List (optionally filter by status)
    func fetchSkills(filterStatus: SkillStatus? = nil, completion: @escaping (Result<[Skill], Error>) -> Void) {
        db.collection("skills")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let docs = snapshot?.documents ?? []

                let skills: [Skill] = docs.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID
                    guard let providerId = data["providerId"] as? String,
                          let name = data["name"] as? String,
                          let statusRaw = data["status"] as? String,
                          let status = SkillStatus(rawValue: statusRaw)
                    else { return nil }

                    let description = data["description"] as? String
                    let proofImageURL = data["proofImageURL"] as? String
                    let adminFeedback = data["adminFeedback"] as? String

                    return Skill(
                        id: id,
                        providerId: providerId,
                        name: name,
                        description: description,
                        proofImageURL: proofImageURL,
                        status: status,
                        adminFeedback: adminFeedback
                    )
                }

                if let filter = filterStatus {
                    completion(.success(skills.filter { $0.status == filter }))
                } else {
                    completion(.success(skills))
                }
            }
    }

    // MARK: - Fetch single Skill
    func fetchSkill(by id: String, completion: @escaping (Result<Skill, Error>) -> Void) {
        db.collection("skills").document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let doc = snapshot, doc.exists, let data = doc.data() else {
                completion(.failure(NSError(domain: "AdminToolsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Skill not found"])))
                return
            }

            guard let providerId = data["providerId"] as? String,
                  let name = data["name"] as? String,
                  let statusRaw = data["status"] as? String,
                  let status = SkillStatus(rawValue: statusRaw)
            else {
                completion(.failure(NSError(domain: "AdminToolsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Malformed skill data"])))
                return
            }

            let description = data["description"] as? String
            let proofImageURL = data["proofImageURL"] as? String
            let adminFeedback = data["adminFeedback"] as? String

            let skill = Skill(id: doc.documentID, providerId: providerId, name: name, description: description, proofImageURL: proofImageURL, status: status, adminFeedback: adminFeedback)
            completion(.success(skill))
        }
    }

    // MARK: - Update Skill Status (approve/reject)
    func updateSkillStatus(skillID: String, status: SkillStatus, adminFeedback: String? = nil, completion: ((Error?) -> Void)? = nil) {
        var data: [String: Any] = ["status": status.rawValue]
        if let feedback = adminFeedback {
            data["adminFeedback"] = feedback
        }

        db.collection("skills").document(skillID).updateData(data) { error in
            completion?(error)
        }
    }

    // MARK: - Fetch User (provider) by ID
    func fetchUser(userID: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let doc = snapshot, doc.exists, let data = doc.data() else {
                completion(.failure(NSError(domain: "AdminToolsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            // Be tolerant with field names and missing fields.
            // Try common keys first, then fall back to alternatives.
            let firstName = (data["firstName"] as? String) ?? (data["first_name"] as? String) ?? ""
            let lastName = (data["lastName"] as? String) ?? (data["last_name"] as? String) ?? ""

            var username = (data["username"] as? String) ?? (data["userName"] as? String) ?? ""
            if username.isEmpty {
                // try to extract from an email or display name
                if let email = data["email"] as? String, let handle = email.split(separator: "@").first {
                    username = String(handle)
                }
            }

            // If no separate first/last but a full name exists, split it.
            if firstName.isEmpty && lastName.isEmpty {
                if let full = (data["name"] as? String) ?? (data["displayName"] as? String) ?? (data["fullName"] as? String) {
                    let parts = full.split(separator: " ")
                    if parts.count >= 2 {
                        // first token -> firstName, rest -> lastName
                        let f = parts.first.map(String.init) ?? ""
                        let l = parts.dropFirst().joined(separator: " ")
                        
                        // use these in place
                        let user = User(id: doc.documentID, firstName: f, lastName: l, username: username.isEmpty ? full : username, email: (data["email"] as? String) ?? "", phoneNumber: (data["phoneNumber"] as? String) ?? "", role: UserRole(rawValue: (data["role"] as? String) ?? "Seeker") ?? .seeker)
                        var mutableUser = user
                        mutableUser.profileImageURL = data["profileImageURL"] as? String
                        mutableUser.location = data["location"] as? String
                        mutableUser.interests = data["interests"] as? [String]
                        mutableUser.favoriteServiceIds = data["favoriteServiceIds"] as? [String]
                        mutableUser.businessName = data["businessName"] as? String
                        mutableUser.bio = data["bio"] as? String
                        mutableUser.isVerified = data["isVerified"] as? Bool
                        if let ts = data["joinedDate"] as? Timestamp { mutableUser.joinedDate = ts.dateValue() }
                        completion(.success(mutableUser))
                        return
                    } else {
                        // single token name; use as username if missing
                        if username.isEmpty { username = full }
                    }
                }
            }

            guard let email = data["email"] as? String,
                let phoneNumber = data["phoneNumber"] as? String,
                let roleRaw = data["role"] as? String,
                let role = UserRole(rawValue: roleRaw)
            else {
                // not enough data, but still try to return a partial user
                let fallbackUser = User(id: doc.documentID, firstName: firstName, lastName: lastName, username: username, email: (data["email"] as? String) ?? "", phoneNumber: (data["phoneNumber"] as? String) ?? "", role: UserRole(rawValue: (data["role"] as? String) ?? "Seeker") ?? .seeker)
                var mutableUser = fallbackUser
                mutableUser.profileImageURL = data["profileImageURL"] as? String
                mutableUser.location = data["location"] as? String
                mutableUser.interests = data["interests"] as? [String]
                mutableUser.favoriteServiceIds = data["favoriteServiceIds"] as? [String]
                mutableUser.businessName = data["businessName"] as? String
                mutableUser.bio = data["bio"] as? String
                mutableUser.isVerified = data["isVerified"] as? Bool
                if let ts = data["joinedDate"] as? Timestamp { mutableUser.joinedDate = ts.dateValue() }
                completion(.success(mutableUser))
                return
            }

            let user = User(id: doc.documentID, firstName: firstName, lastName: lastName, username: username, email: email, phoneNumber: phoneNumber, role: role)
            var mutableUser = user
            mutableUser.profileImageURL = data["profileImageURL"] as? String
            mutableUser.location = data["location"] as? String
            mutableUser.activeProfileMode = ProfileMode(rawValue: (data["activeProfileMode"] as? String) ?? "")
            mutableUser.interests = data["interests"] as? [String]
            mutableUser.favoriteServiceIds = data["favoriteServiceIds"] as? [String]
            mutableUser.businessName = data["businessName"] as? String
            mutableUser.bio = data["bio"] as? String
            mutableUser.isVerified = data["isVerified"] as? Bool
            if let ts = data["joinedDate"] as? Timestamp { mutableUser.joinedDate = ts.dateValue() }

            completion(.success(mutableUser))
        }
    }

    // MARK: - Fetch All Users (optional role filter)
    func fetchUsers(role: UserRole? = nil, completion: @escaping (Result<[User], Error>) -> Void) {
        var query: Query = db.collection("users")
        if let role = role {
            query = query.whereField("role", isEqualTo: role.rawValue)
        }

        query.order(by: "joinedDate", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let docs = snapshot?.documents ?? []
            let users: [User] = docs.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                guard let firstName = data["firstName"] as? String,
                      let lastName = data["lastName"] as? String,
                      let username = data["username"] as? String,
                      let email = data["email"] as? String,
                      let phoneNumber = data["phoneNumber"] as? String,
                      let roleRaw = data["role"] as? String,
                      let role = UserRole(rawValue: roleRaw),
                      let joinedDate = data["joinedDate"] as? Timestamp
                else { return nil }

                var user = User(id: id, firstName: firstName, lastName: lastName, username: username, email: email, phoneNumber: phoneNumber, role: role)
                user.joinedDate = joinedDate.dateValue()
                user.profileImageURL = data["profileImageURL"] as? String
                user.location = data["location"] as? String
                user.activeProfileMode = ProfileMode(rawValue: (data["activeProfileMode"] as? String) ?? "")
                user.interests = data["interests"] as? [String]
                user.favoriteServiceIds = data["favoriteServiceIds"] as? [String]
                user.businessName = data["businessName"] as? String
                user.bio = data["bio"] as? String
                user.isVerified = data["isVerified"] as? Bool

                return user
            }

            completion(.success(users))
        }
    }

    // MARK: - Update user flags (suspend/ban/verify)
    func updateUserFlags(userID: String, isSuspended: Bool? = nil, isBanned: Bool? = nil, isVerified: Bool? = nil, completion: ((Error?) -> Void)? = nil) {
        var data: [String: Any] = [:]
        if let s = isSuspended { data["isSuspended"] = s }
        if let b = isBanned { data["isBanned"] = b }
        if let v = isVerified { data["isVerified"] = v }

        guard !data.isEmpty else { completion?(nil); return }

        db.collection("users").document(userID).updateData(data) { error in
            completion?(error)
        }
    }

    // MARK: - Fetch Reports (optionally filter by status)
    func fetchReports(filterStatus: String? = nil, completion: @escaping (Result<[Report], Error>) -> Void) {
        var query: Query = db.collection("reports")
        if let status = filterStatus {
            query = query.whereField("status", isEqualTo: status)
        }

        query.order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let docs = snapshot?.documents ?? []
            print("ℹ️ fetchReports: raw document count = \(docs.count)")
            let reports: [Report] = docs.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID

                func stringForKeys(_ keys: [String]) -> String? {
                    for k in keys {
                        if let v = data[k] as? String, !v.isEmpty { return v }
                    }
                    return nil
                }

                guard let reporterId = stringForKeys(["reporterId", "reporterID", "reporter"]),
                      let reportedUserId = stringForKeys(["reportedUserId", "reportedUserID", "reportedId", "reported_user_id"]) 
                else {
                    print("⚠️ fetchReports: skipping doc id=\(id) because reporter/reported id missing")
                    return nil
                }

                guard let reason = stringForKeys(["reason", "type", "title"]), !reason.isEmpty else {
                    print("⚠️ fetchReports: skipping doc id=\(id) because reason is missing")
                    return nil
                }

                let description = stringForKeys(["description", "details", "body"]) ?? ""
                let status = stringForKeys(["status", "state"]) ?? "Open"

                var tsDate: Date = Date()
                if let ts = data["timestamp"] as? Timestamp {
                    tsDate = ts.dateValue()
                } else if let num = data["timestamp"] as? Double {
                    tsDate = Date(timeIntervalSince1970: num)
                } else if let num = data["timestamp"] as? Int {
                    tsDate = Date(timeIntervalSince1970: TimeInterval(num))
                } else if let s = data["timestamp"] as? String {
                    let fmt = ISO8601DateFormatter()
                    if let d = fmt.date(from: s) { tsDate = d }
                }

                let evidenceImageURL = data["evidenceImageURL"] as? String

                return Report(id: id,
                              reporterId: reporterId,
                              reportedUserId: reportedUserId,
                              reason: reason,
                              description: description,
                              evidenceImageURL: evidenceImageURL,
                              status: status,
                              timestamp: tsDate)
            }

            completion(.success(reports))
        }
    }

    // MARK: - Fetch Reports for a specific reported user
    func fetchReportsForUser(reportedUserID: String, completion: @escaping (Result<[Report], Error>) -> Void) {
        // Use tolerant parsing similar to fetchReports
        db.collection("reports")
            .whereField("reportedUserId", isEqualTo: reportedUserID)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let docs = snapshot?.documents ?? []
                let reports: [Report] = docs.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID

                    func stringForKeys(_ keys: [String]) -> String? {
                        for k in keys {
                            if let v = data[k] as? String, !v.isEmpty { return v }
                        }
                        return nil
                    }

                    guard let reporterId = stringForKeys(["reporterId", "reporterID", "reporter"]),
                          let reportedUserId = stringForKeys(["reportedUserId", "reportedUserID", "reportedId", "reported_user_id"]) 
                    else {
                        print("⚠️ fetchReports: skipping doc id=\(id) because reporter/reported id missing")
                        return nil
                    }

                    guard let reason = stringForKeys(["reason", "type", "title"]), !reason.isEmpty else {
                        print("⚠️ fetchReports: skipping doc id=\(id) because reason is missing")
                        return nil
                    }
                    let description = stringForKeys(["description", "details", "body"]) ?? ""
                    let status = stringForKeys(["status", "state"]) ?? "Open"

                    var tsDate: Date = Date()
                    if let ts = data["timestamp"] as? Timestamp {
                        tsDate = ts.dateValue()
                    } else if let num = data["timestamp"] as? Double {
                        tsDate = Date(timeIntervalSince1970: num)
                    } else if let num = data["timestamp"] as? Int {
                        tsDate = Date(timeIntervalSince1970: TimeInterval(num))
                    } else if let s = data["timestamp"] as? String {
                        let fmt = ISO8601DateFormatter()
                        if let d = fmt.date(from: s) { tsDate = d }
                    }

                    let evidenceImageURL = data["evidenceImageURL"] as? String

                    return Report(id: id,
                                  reporterId: reporterId,
                                  reportedUserId: reportedUserId,
                                  reason: reason,
                                  description: description,
                                  evidenceImageURL: evidenceImageURL,
                                  status: status,
                                  timestamp: tsDate)
                }

                completion(.success(reports))
            }
    }

    // MARK: - Fetch single Report
    func fetchReport(by id: String, completion: @escaping (Result<Report, Error>) -> Void) {
        db.collection("reports").document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let doc = snapshot, doc.exists, let data = doc.data() else {
                completion(.failure(NSError(domain: "AdminToolsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Report not found"])))
                return
            }

            func stringForKeys(_ keys: [String]) -> String? {
                for k in keys {
                    if let v = data[k] as? String, !v.isEmpty { return v }
                }
                return nil
            }

            guard let reporterId = stringForKeys(["reporterId", "reporterID", "reporter"]),
                  let reportedUserId = stringForKeys(["reportedUserId", "reportedUserID", "reportedId", "reported_user_id"]) else {
                completion(.failure(NSError(domain: "AdminToolsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Malformed report data"])))
                return
            }

            let reason = stringForKeys(["reason", "type", "title"]) ?? ""
            let description = stringForKeys(["description", "details", "body"]) ?? ""
            let status = stringForKeys(["status", "state"]) ?? "Open"

            var tsDate: Date = Date()
            if let ts = data["timestamp"] as? Timestamp {
                tsDate = ts.dateValue()
            } else if let num = data["timestamp"] as? Double {
                tsDate = Date(timeIntervalSince1970: num)
            } else if let num = data["timestamp"] as? Int {
                tsDate = Date(timeIntervalSince1970: TimeInterval(num))
            } else if let s = data["timestamp"] as? String {
                let fmt = ISO8601DateFormatter()
                if let d = fmt.date(from: s) { tsDate = d }
            }

            let evidenceImageURL = data["evidenceImageURL"] as? String

            let report = Report(id: doc.documentID,
                                reporterId: reporterId,
                                reportedUserId: reportedUserId,
                                reason: reason,
                                description: description,
                                evidenceImageURL: evidenceImageURL,
                                status: status,
                                timestamp: tsDate)

            completion(.success(report))
        }
    }

    // MARK: - Update Report Status
    func updateReportStatus(reportID: String, status: String, completion: ((Error?) -> Void)? = nil) {
        db.collection("reports").document(reportID).updateData(["status": status]) { error in
            completion?(error)
        }
    }

    // MARK: - Update Report Fields
    func updateReport(reportID: String, reason: String? = nil, description: String? = nil, evidenceImageURL: String? = nil, status: String? = nil, completion: ((Error?) -> Void)? = nil) {
        var data: [String: Any] = [:]
        if let r = reason { data["reason"] = r }
        if let d = description { data["description"] = d }
        if let e = evidenceImageURL { data["evidenceImageURL"] = e }
        if let s = status { data["status"] = s }

        guard !data.isEmpty else { completion?(nil); return }

        db.collection("reports").document(reportID).updateData(data) { error in
            completion?(error)
        }
    }

    // MARK: - Add Category
    func addCategory(name: String, completion: ((Error?) -> Void)? = nil) {
        let category = ServiceCategory(
            id: nil,
            name: name,
            iconURL: nil,
            isActive: true
        )

        do {
            _ = try db.collection("serviceCategories").addDocument(from: category)
            completion?(nil)
        } catch {
            completion?(error)
        }
    }

    // MARK: - Update Category Status
    func updateCategoryStatus(categoryID: String, isActive: Bool) {
        db.collection("serviceCategories")
            .document(categoryID)
            .updateData(["isActive": isActive])
    }

    // MARK: - Rename Category
    func renameCategory(categoryID: String, newName: String) {
        db.collection("serviceCategories")
            .document(categoryID)
            .updateData(["name": newName])
    }

    
}
