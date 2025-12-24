/// File: RoleSelectionViewController.swift
/// Purpose: Class RoleSelectionViewController, func viewDidLoad, func prepare.
/// Location: Features/Authentication/RoleSelectionViewController.swift

import UIKit

/// Class RoleSelectionViewController: Responsible for the lifecycle, state, and behavior related to RoleSelectionViewController.
class RoleSelectionViewController: UIViewController {

    /// Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    /**
     Prepares for the segue.
     
     - Parameters:
        - segue: The UIStoryboardSegue object containing information about the view controllers involved in the segue.
        - sender: The object that initiated the segue.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
        // Solution: Use 'is' to check type instead of 'as?' which creates a variable.
        if segue.destination is SignUpViewController {
            
            if segue.identifier == "goToSignUpSeeker" {
                print("Selected Role: Seeker (Default)")
                
            } else if segue.identifier == "goToSignUpProvider" {
                print("Selected Role: Provider (Will sign up as Seeker first)")
            }
        }
    }
}
