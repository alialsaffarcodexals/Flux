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
            
            // ✅ الحل: نستخدم 'is' للتحقق من النوع بدلاً من 'as?' التي تنشئ متغيراً
            if segue.destination is SignUpViewController {
                
                if segue.identifier == "goToSignUpSeeker" {
                    print("Selected Role: Seeker (Default)")
                    
                } else if segue.identifier == "goToSignUpProvider" {
                    print("Selected Role: Provider (Will sign up as Seeker first)")
                }
            }
        }
}
