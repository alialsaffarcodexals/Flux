import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProviderProfileViewModel {
    
    // MARK: - Bindings
    // MARK: - Bindings
    var onError: ((String) -> Void)?
    var onSwitchToBuyer: ((User) -> Void)?
    var onUserDataUpdated: ((User) -> Void)? // New Binding
    var onSkillsUpdated: (([Skill]) -> Void)?
    var onLoading: ((Bool) -> Void)?
    
    // MARK: - Fetch Data
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        onLoading?(true)
        
        UserRepository.shared.getUser(uid: uid) { [weak self] result in
            
            // Note: We don't hide loading here because we might fetch skills right after or in parallel.
            // But if this is standalone, we should.
            // It's safer to just hide it here, and if fetchSkills is called, it triggers loading again.
            self?.onLoading?(false)
            
            switch result {
            case .success(let user):
                self?.onUserDataUpdated?(user)
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Actions
    func didTapServiceSeekerProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        onLoading?(true)
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "activeProfileMode": ProfileMode.buyerMode.rawValue
        ]) { [weak self] error in
            
            self?.onLoading?(false)
            
            if let error = error {
                self?.onError?(error.localizedDescription)
                return
            }
            
            self?.onLoading?(true) // Fetching user again
            
            UserRepository.shared.getUser(uid: uid) { result in
                
                self?.onLoading?(false)
                
                switch result {
                case .success(let updatedUser):
                    self?.onSwitchToBuyer?(updatedUser)
                case .failure(let error):
                    self?.onError?("Failed to switch modes: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchSkills(providerId: String) {
        // This might be called in parallel with fetchUserProfile
        // We'll trust the VC to handle multiple onLoading calls or just let it flicker if needed. 
        // But better: ActivityIndicator logic in VC handles multiple calls if we used a counter, but our extension is simple bool check.
        // Simple approach: show on start, hide on end.
        
        onLoading?(true)
        
        SkillRepository.shared.fetchSkills(for: providerId) { [weak self] result in
            
            self?.onLoading?(false)
            
            switch result {
            case .success(let skills):
                self?.onSkillsUpdated?(skills)
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Portfolio Fetching
    var onPortfolioUpdated: (([PortfolioProject]) -> Void)?

    func fetchPortfolio(providerId: String) {
        onLoading?(true)
        PortfolioRepository.shared.fetchPortfolioProjects(providerId: providerId) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)
                switch result {
                case .success(let projects):
                    self?.onPortfolioUpdated?(projects)
                case .failure(let error):
                    print("Error fetching portfolio: \(error.localizedDescription)")
                    // Optionally report error
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Service Packages Fetching
    var onServicePackagesUpdated: (([ServicePackage]) -> Void)?
    
    func fetchServicePackages(providerId: String) {
        onLoading?(true)
        FirestoreServicePackagesRepository.shared.fetchPackagesForProvider(providerId: providerId) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)
                switch result {
                case .success(let packages):
                    self?.onServicePackagesUpdated?(packages)
                case .failure(let error):
                    print("Error fetching service packages: \(error.localizedDescription)")
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Profile Image Update
    func updateProviderProfileImage(image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else {
            onError?("User not authenticated")
            return
        }
        
        print("Image selected for Provider profile")
        onLoading?(true)
        
        // Convert image to data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            onLoading?(false)
            onError?("Failed to process image")
            return
        }
        
        let fileName = "\(uid)_provider_profile.jpg"
        print("Upload started for Provider profile image")
        
        // Upload to Cloudinary
        StorageManager.shared.uploadProfilePicture(with: imageData, fileName: fileName) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let imageURL):
                print("Upload success URL: \(imageURL)")
                
                // Update Firestore
                UserRepository.shared.updateUserField(
                    uid: uid,
                    field: "providerProfileImageURL",
                    value: imageURL
                ) { updateResult in
                    DispatchQueue.main.async {
                        self.onLoading?(false)
                        
                        switch updateResult {
                        case .success:
                            print("Firestore write success for providerProfileImageURL")
                            // Refresh user profile to get updated data
                            self.fetchUserProfile()
                        case .failure(let error):
                            print("Firestore write error: \(error.localizedDescription)")
                            self.onError?("Failed to save image: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.onLoading?(false)
                    print("Upload error: \(error.localizedDescription)")
                    self.onError?("Failed to upload image: \(error.localizedDescription)")
                }
            }
        }
    }
}
