/*
 File: RoleSelectionViewController.swift
 Purpose: class RoleSelectionViewController, func viewDidLoad, func prepare
 Location: Features/Authentication/RoleSelectionViewController.swift
*/









import UIKit



/// Class RoleSelectionViewController: Responsible for the lifecycle, state, and behavior related to RoleSelectionViewController.
class RoleSelectionViewController: UIViewController {



/// @Description: Performs the viewDidLoad operation.
/// @Input: None
/// @Output: Void
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    


/// @Description: Performs the prepare operation.
/// @Input: for segue: UIStoryboardSegue; sender: Any?
/// @Output: Void
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        
        
        print("🔄 Preparing segue: \(segue.identifier ?? "No Identifier")")
        if let signUpVC = segue.destination as? SignUpViewController {
            
            if segue.identifier == "goToSignUpSeeker" {
                signUpVC.userRole = "Seeker" 
                print("Selected Role: Seeker")
            } else if segue.identifier == "goToSignUpProvider" {
                signUpVC.userRole = "Provider" 
                print("Selected Role: Provider")
            }
        }
    }
}
