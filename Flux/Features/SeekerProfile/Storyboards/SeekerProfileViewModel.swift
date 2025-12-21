/*
 File: SeekerProfileViewModel.swift
 Purpose: class SeekerProfileViewModel, func fetchUserProfile
 Location: Features/SeekerProfile/Storyboards/SeekerProfileViewModel.swift
*/









import Foundation
import FirebaseAuth
import FirebaseFirestore



/// Class SeekerProfileViewModel: Responsible for the lifecycle, state, and behavior related to SeekerProfileViewModel.
class SeekerProfileViewModel {
    
    
    
    var onUserDataUpdated: ((User) -> Void)?
    var onError: ((String) -> Void)?
    


/// @Description: Performs the fetchUserProfile operation.
/// @Input: None
/// @Output: Void
    func fetchUserProfile() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.onError?("No user logged in")
            return
        }
        
        
        FirestoreManager.shared.getUser(uid: uid) { [weak self] result in
            switch result {
            case .success(let user):
                
                self?.onUserDataUpdated?(user)
                
            case .failure(let error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
}
