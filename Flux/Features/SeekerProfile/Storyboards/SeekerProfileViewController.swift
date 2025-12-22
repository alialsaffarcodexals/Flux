/*
 File: SeekerProfileViewController.swift
 Purpose: class SeekerProfileViewController, func viewDidLoad, func setupBindings
 Location: Features/SeekerProfile/Storyboards/SeekerProfileViewController.swift
*/









import UIKit




/// Class SeekerProfileViewController: Responsible for the lifecycle, state, and behavior related to SeekerProfileViewController.
class SeekerProfileViewController: UIViewController {

    
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel! 
    
    
        var viewModel = SeekerProfileViewModel()



/// @Description: Performs the viewDidLoad operation.
/// @Input: None
/// @Output: Void
        override func viewDidLoad() {
            super.viewDidLoad()
            setupBindings() 
            viewModel.fetchUserProfile() 
            
            
            locationLabel.text = "Bahrain 🇧🇭"
        }

        


/// @Description: Performs the setupBindings operation.
/// @Input: None
/// @Output: Void
        func setupBindings() {
            
            
            viewModel.onUserDataUpdated = { [weak self] user in
                DispatchQueue.main.async {
                    self?.nameLabel.text = user.name
                    self?.usernameLabel.text = "@\(user.username)"
                    
                    
                    if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                        
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: url) {
                                DispatchQueue.main.async {
                                    self?.profileImageView.image = UIImage(data: data)
                                }
                            }
                        }
                    }
                }
            }
            
            viewModel.onError = { errorMessage in
                print("Error fetching profile: \(errorMessage)")
            }
        }
    }
   
