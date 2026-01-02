import Foundation
import FirebaseFirestore
import FirebaseAuth

class AdminToolsViewModel {

    var title: String {
        return "Dashboard"
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
                        // Admin dashboard treats 'Requested' bookings as the pending count
                        case .requested: pending += 1
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

                    // Parse skill level from possible fields and tolerant formats
                    var level: SkillLevel? = nil
                    if let levelRaw = (data["level"] as? String) ?? (data["skillLevel"] as? String) {
                        if let parsed = SkillLevel(rawValue: levelRaw) {
                            level = parsed
                        } else {
                            switch levelRaw.lowercased() {
                            case "beginner": level = .beginner
                            case "intermediate": level = .intermediate
                            case "expert": level = .expert
                            default: level = nil
                            }
                        }
                    }

                    return Skill(
                        id: id,
                        providerId: providerId,
                        name: name,
                        level: level,
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

            // Parse skill level (tolerant to field name and casing)
            var level: SkillLevel? = nil
            if let levelRaw = (data["level"] as? String) ?? (data["skillLevel"] as? String) {
                if let parsed = SkillLevel(rawValue: levelRaw) {
                    level = parsed
                } else {
                    switch levelRaw.lowercased() {
                    case "beginner": level = .beginner
                    case "intermediate": level = .intermediate
                    case "expert": level = .expert
                    default: level = nil
                    }
                }
            }

            let skill = Skill(id: doc.documentID, providerId: providerId, name: name, level: level, description: description, proofImageURL: proofImageURL, status: status, adminFeedback: adminFeedback)
            completion(.success(skill))
        }
    }

    // MARK: - Update Skill Status (approve/reject)
    func updateSkillStatus(skillID: String, status: SkillStatus, adminFeedback: String? = nil, completion: ((Error?) -> Void)? = nil) {
        var data: [String: Any] = ["status": status.rawValue]
        if let feedback = adminFeedback {
            data["adminFeedback"] = feedback
        }

        db.collection("skills").document(skillID).updateData(data) { [weak self] error in
            completion?(error)
            guard error == nil else { return }
            // create an activity notification for this admin action
            if let self = self {
                let title = status == .approved ? "Skill approved" : "Skill rejected"
                var message = ""
                if let fb = adminFeedback, !fb.isEmpty { message = fb }
                self.createActivityNotification(title: title, message: message, toUserId: "")
            }
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
                        // Support both old and new field names for backward compatibility
                        let legacy = data["profileImageURL"] as? String
                        mutableUser.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? legacy
                        mutableUser.providerProfileImageURL = data["providerProfileImageURL"] as? String
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
                // Support both old and new field names for backward compatibility
                let legacy = data["profileImageURL"] as? String
                mutableUser.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? legacy
                mutableUser.providerProfileImageURL = data["providerProfileImageURL"] as? String
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
            // Support both old and new field names for backward compatibility
            let legacy = data["profileImageURL"] as? String
            mutableUser.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? legacy
            mutableUser.providerProfileImageURL = data["providerProfileImageURL"] as? String
            mutableUser.location = data["location"] as? String
            mutableUser.activeProfileMode = ProfileMode(rawValue: (data["activeProfileMode"] as? String) ?? "")
            mutableUser.interests = data["interests"] as? [String]
            mutableUser.favoriteServiceIds = data["favoriteServiceIds"] as? [String]
            mutableUser.businessName = data["businessName"] as? String
            mutableUser.bio = data["bio"] as? String
            mutableUser.isVerified = data["isVerified"] as? Bool
            // Account flags (suspension/ban)
            mutableUser.isSuspended = data["isSuspended"] as? Bool
            mutableUser.isBanned = data["isBanned"] as? Bool
            if let ts = data["suspendedUntil"] as? Timestamp { mutableUser.suspendedUntil = ts.dateValue() }
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
                // Support both old and new field names for backward compatibility
                let legacy = data["profileImageURL"] as? String
                user.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? legacy
                user.providerProfileImageURL = data["providerProfileImageURL"] as? String
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

    // MARK: - Tolerant user lookup by identifier
    /// Tries to resolve a user by document ID first, then by common fields like `username`, `email`, or `displayName`.
    func fetchUserByIdentifier(_ identifier: String, completion: @escaping (Result<User, Error>) -> Void) {
        // Try by document ID first
        fetchUser(userID: identifier) { result in
            switch result {
            case .success(let user):
                completion(.success(user))
            case .failure:
                // Fallback to query by username, email or displayName
                self.db.collection("users")
                    .whereField("username", isEqualTo: identifier)
                    .limit(to: 1)
                    .getDocuments { snap, error in
                        if error != nil {
                            // try email / displayName queries sequentially
                            self.db.collection("users").whereField("email", isEqualTo: identifier).limit(to: 1).getDocuments { s2, e2 in
                                if let e2 = e2 {
                                    completion(.failure(e2))
                                    return
                                }
                                if let doc = s2?.documents.first, let data = doc.data() as [String: Any]? {
                                    // decode minimal user
                                    let id = doc.documentID
                                    let firstName = (data["firstName"] as? String) ?? ""
                                    let lastName = (data["lastName"] as? String) ?? ""
                                    let username = (data["username"] as? String) ?? (data["displayName"] as? String) ?? identifier
                                    let email = (data["email"] as? String) ?? ""
                                    let phone = (data["phoneNumber"] as? String) ?? ""
                                    let role = UserRole(rawValue: (data["role"] as? String) ?? "Seeker") ?? .seeker
                                    var user = User(id: id, firstName: firstName, lastName: lastName, username: username, email: email, phoneNumber: phone, role: role)
                                    // Support both old and new field names for backward compatibility
                                    user.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? (data["profileImageURL"] as? String)
                                    user.providerProfileImageURL = data["providerProfileImageURL"] as? String
                                    completion(.success(user))
                                    return
                                }

                                // last attempt: displayName search
                                self.db.collection("users").whereField("displayName", isEqualTo: identifier).limit(to: 1).getDocuments { s3, e3 in
                                    if let e3 = e3 {
                                        completion(.failure(e3))
                                        return
                                    }
                                    if let doc = s3?.documents.first, let data = doc.data() as [String: Any]? {
                                        let id = doc.documentID
                                        let firstName = (data["firstName"] as? String) ?? ""
                                        let lastName = (data["lastName"] as? String) ?? ""
                                        let username = (data["username"] as? String) ?? (data["displayName"] as? String) ?? identifier
                                        let email = (data["email"] as? String) ?? ""
                                        let phone = (data["phoneNumber"] as? String) ?? ""
                                        let role = UserRole(rawValue: (data["role"] as? String) ?? "Seeker") ?? .seeker
                                        var user = User(id: id, firstName: firstName, lastName: lastName, username: username, email: email, phoneNumber: phone, role: role)
                                        // Support both old and new field names for backward compatibility
                                    user.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? (data["profileImageURL"] as? String)
                                    user.providerProfileImageURL = data["providerProfileImageURL"] as? String
                                        completion(.success(user))
                                        return
                                    }

                                    completion(.failure(NSError(domain: "AdminToolsViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                                }
                            }
                            return
                        }

                        if let doc = snap?.documents.first, let data = doc.data() as [String: Any]? {
                            let id = doc.documentID
                            let firstName = (data["firstName"] as? String) ?? ""
                            let lastName = (data["lastName"] as? String) ?? ""
                            let username = (data["username"] as? String) ?? (data["displayName"] as? String) ?? identifier
                            let email = (data["email"] as? String) ?? ""
                            let phone = (data["phoneNumber"] as? String) ?? ""
                            let role = UserRole(rawValue: (data["role"] as? String) ?? "Seeker") ?? .seeker
                            var user = User(id: id, firstName: firstName, lastName: lastName, username: username, email: email, phoneNumber: phone, role: role)
                            // Support both old and new field names for backward compatibility
                            let legacy = data["profileImageURL"] as? String
                            user.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? legacy
                            user.providerProfileImageURL = data["providerProfileImageURL"] as? String
                            completion(.success(user))
                            return
                        }

                        // If for some reason nothing matched, try email/displayName as above
                        self.db.collection("users").whereField("email", isEqualTo: identifier).limit(to: 1).getDocuments { s2, e2 in
                            if let e2 = e2 {
                                completion(.failure(e2)); return
                            }
                            if let doc = s2?.documents.first, let data = doc.data() as [String: Any]? {
                                let id = doc.documentID
                                let firstName = (data["firstName"] as? String) ?? ""
                                let lastName = (data["lastName"] as? String) ?? ""
                                let username = (data["username"] as? String) ?? (data["displayName"] as? String) ?? identifier
                                let email = (data["email"] as? String) ?? ""
                                let phone = (data["phoneNumber"] as? String) ?? ""
                                let role = UserRole(rawValue: (data["role"] as? String) ?? "Seeker") ?? .seeker
                                var user = User(id: id, firstName: firstName, lastName: lastName, username: username, email: email, phoneNumber: phone, role: role)
                                // Support both old and new field names for backward compatibility
                                let legacy = data["profileImageURL"] as? String
                                user.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? legacy
                                user.providerProfileImageURL = data["providerProfileImageURL"] as? String
                                completion(.success(user))
                                return
                            }

                            self.db.collection("users").whereField("displayName", isEqualTo: identifier).limit(to: 1).getDocuments { s3, e3 in
                                if let e3 = e3 { completion(.failure(e3)); return }
                                if let doc = s3?.documents.first, let data = doc.data() as [String: Any]? {
                                    let id = doc.documentID
                                    let firstName = (data["firstName"] as? String) ?? ""
                                    let lastName = (data["lastName"] as? String) ?? ""
                                    let username = (data["username"] as? String) ?? (data["displayName"] as? String) ?? identifier
                                    let email = (data["email"] as? String) ?? ""
                                    let phone = (data["phoneNumber"] as? String) ?? ""
                                    let role = UserRole(rawValue: (data["role"] as? String) ?? "Seeker") ?? .seeker
                                    var user = User(id: id, firstName: firstName, lastName: lastName, username: username, email: email, phoneNumber: phone, role: role)
                                    // Support both old and new field names for backward compatibility
                                    user.seekerProfileImageURL = (data["seekerProfileImageURL"] as? String) ?? (data["profileImageURL"] as? String)
                                    user.providerProfileImageURL = data["providerProfileImageURL"] as? String
                                    completion(.success(user))
                                    return
                                }

                                completion(.failure(NSError(domain: "AdminToolsViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Update user flags (suspend/ban/verify)
    func updateUserFlags(userID: String,
                         isSuspended: Bool? = nil,
                         isBanned: Bool? = nil,
                         isVerified: Bool? = nil,
                         suspendedUntil: Date? = nil,
                         removeSuspendedUntil: Bool = false,
                         completion: ((Error?) -> Void)? = nil) {

        var data: [String: Any] = [:]
        if let s = isSuspended { data["isSuspended"] = s }
        if let b = isBanned { data["isBanned"] = b }
        if let v = isVerified { data["isVerified"] = v }
        if let dt = suspendedUntil { data["suspendedUntil"] = Timestamp(date: dt) }
        if removeSuspendedUntil { data["suspendedUntil"] = FieldValue.delete() }

        guard !data.isEmpty else { completion?(nil); return }

        db.collection("users").document(userID).updateData(data) { [weak self] error in
            completion?(error)
            guard error == nil else { return }
            // notify the user about account flag changes
            if let self = self {
                var parts: [String] = []
                if let s = isSuspended { parts.append(s ? "suspended" : "unsuspended") }
                if let b = isBanned { parts.append(b ? "banned" : "unbanned") }
                if let v = isVerified { parts.append(v ? "verified" : "unverified") }
                let message = parts.joined(separator: ", ")
                let title = "Account update"
                self.createActivityNotification(title: title, message: message, toUserId: userID)
            }
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
                              timestamp: tsDate,
                              answer: nil)
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
                                  timestamp: tsDate,
                                  answer: nil)
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
            let answer = data["answer"] as? String

            let report = Report(id: doc.documentID,
                                reporterId: reporterId,
                                reportedUserId: reportedUserId,
                                reason: reason,
                                description: description,
                                evidenceImageURL: evidenceImageURL,
                                status: status,
                                timestamp: tsDate,
                                answer: answer)

            completion(.success(report))
        }
    }

    // MARK: - Update Report Status
    func updateReportStatus(reportID: String, status: String, completion: ((Error?) -> Void)? = nil) {
        db.collection("reports").document(reportID).updateData(["status": status]) { [weak self] error in
            completion?(error)
            guard error == nil else { return }
            // create an activity notification for the report update
            if let self = self {
                let title = "Report updated"
                let message = "Status set to \(status)"
                self.createActivityNotification(title: title, message: message, toUserId: "")
            }
        }
    }

    // MARK: - Update Report Fields
    func updateReport(reportID: String, reason: String? = nil, description: String? = nil, evidenceImageURL: String? = nil, status: String? = nil, answer: String? = nil, completion: ((Error?) -> Void)? = nil) {
        var data: [String: Any] = [:]
        if let r = reason { data["reason"] = r }
        if let d = description { data["description"] = d }
        if let e = evidenceImageURL { data["evidenceImageURL"] = e }
        if let s = status { data["status"] = s }
        if let a = answer { data["answer"] = a }

        guard !data.isEmpty else { completion?(nil); return }

        db.collection("reports").document(reportID).updateData(data) { [weak self] error in
            completion?(error)
            guard error == nil else { return }
            if let self = self {
                let title = "Report modified"
                let message = (reason ?? "Report updated")
                self.createActivityNotification(title: title, message: message, toUserId: "")
            }
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
            // notify about new category
            self.createActivityNotification(title: "Category added", message: name, toUserId: "all")
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
            .updateData(["name": newName]) { [weak self] error in
                guard error == nil else { return }
                self?.createActivityNotification(title: "Category renamed", message: newName, toUserId: "all")
            }
    }

    // MARK: - Delete Category
    func deleteCategory(categoryID: String, completion: ((Error?) -> Void)? = nil) {
        db.collection("serviceCategories")
            .document(categoryID)
            .delete { [weak self] error in
                completion?(error)
                guard error == nil else { return }
                self?.createActivityNotification(title: "Category deleted", message: categoryID, toUserId: "all")
            }
    }

    // MARK: - Activity notification helper
    private func createActivityNotification(title: String, message: String, toUserId: String) {
        guard let admin = Auth.auth().currentUser else { return }
        let fromId = admin.uid
        let fromName = admin.displayName ?? "Admin"

        let payload: [String: Any] = [
            "title": title,
            "message": message,
            "type": NotificationType.activity.rawValue,
            "fromUserId": fromId,
            "fromName": fromName,
            "toUserId": toUserId.isEmpty ? "all" : toUserId,
            "createdAt": FieldValue.serverTimestamp(),
            "isRead": false
        ]

        db.collection("notifications").addDocument(data: payload)
    }

    
}
