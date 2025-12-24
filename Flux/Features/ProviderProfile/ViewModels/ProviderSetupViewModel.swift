import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProviderSetupViewModel {

    // MARK: - Bindings
    var onLoadingChanged: ((Bool) -> Void)?
    var onSuccess: ((User) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Actions
    func submitProviderSetup(businessName: String?, bio: String?) {
        // 1. Validate Input
        let business = (businessName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let about = (bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !business.isEmpty else {
            onError?("Please enter your business name.")
            return
        }
        guard !about.isEmpty else {
            onError?("Please enter a short bio.")
            return
        }

        // 2. Check Auth
        guard let uid = Auth.auth().currentUser?.uid else {
            onError?("You’re not logged in. Please log in again.")
            return
        }

        onLoadingChanged?(true)

        // 3. Prepare Update Data
        // We set role to provider AND switch them to Seller Mode immediately
        let updates: [String: Any] = [
            "businessName": business,
            "bio": about,
            "role": UserRole.provider.rawValue,
            "activeProfileMode": ProfileMode.sellerMode.rawValue
        ]

        let db = Firestore.firestore()
        
        // 4. Update Firestore
        db.collection("users").document(uid).setData(updates, merge: true) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.onLoadingChanged?(false)
                self.onError?(error.localizedDescription)
                return
            }

            // 5. Fetch the Updated User Profile
            // We must fetch the fresh data so AppNavigator knows the role changed
            db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.onLoadingChanged?(false)

                    if let error = error {
                        self.onError?(error.localizedDescription)
                        return
                    }

                    // FIX: Use standard Firestore Codable decoding
                    do {
                        if let user = try snapshot?.data(as: User.self) {
                            self.onSuccess?(user)
                        } else {
                            self.onError?("Failed to decode user profile.")
                        }
                    } catch {
                        self.onError?("Error parsing user data: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

