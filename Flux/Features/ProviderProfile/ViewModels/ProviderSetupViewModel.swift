import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProviderSetupViewModel {

    // MARK: - Bindings
    var onLoadingChanged: ((Bool) -> Void)?
    var onSuccess: ((User) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Actions
    // Updated signature to accept location
    func submitProviderSetup(businessName: String?, location: String?, bio: String?) {
        
        // 1. Validate Input
        let business = (businessName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let loc = (location ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let about = (bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !business.isEmpty else {
            onError?("Please enter your business name.")
            return
        }
        
        // Optional: Enforce location existence
        guard !loc.isEmpty else {
            onError?("Please enter your location (e.g., Manama, Bahrain).")
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
        // Added 'location' to the dictionary
        let updates: [String: Any] = [
            "businessName": business,
            "location": loc,
            "bio": about,
            "role": UserRole.provider.rawValue,
            "activeProfileMode": ProfileMode.sellerMode.rawValue,
            "hasCompletedProviderSetup": true             // ✅ Set the new flag
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
            db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.onLoadingChanged?(false)

                    if let error = error {
                        self.onError?(error.localizedDescription)
                        return
                    }

                    do {
                        // User is Codable, so it will automatically map the "location" field
                        // from Firestore to the User.location property.
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
