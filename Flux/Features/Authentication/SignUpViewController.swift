/*
 File: SignUpViewController.swift
 Purpose: class SignUpViewController, func viewDidLoad, func setupUI, extension SignUpViewController, func imagePickerController, func imagePickerControllerDidCancel, extension SignUpViewController, func showAlert
 Location: Features/Authentication/SignUpViewController.swift
*/









import UIKit



/// Class SignUpViewController: Responsible for the lifecycle, state, and behavior related to SignUpViewController.
class SignUpViewController: UIViewController {

    private let viewModel = AuthViewModel()
    private var selectedImage: UIImage?

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editImageButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    
    var userRole: String = "Seeker"
    


/// @Description: Performs the viewDidLoad operation.
/// @Input: None
/// @Output: Void
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    


/// @Description: Performs the setupUI operation.
/// @Input: None
/// @Output: Void
    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    }

    @IBAction func editImageButtonTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        print("🟢 1. Button Tapped")
                
                let imageData = selectedImage?.jpegData(compressionQuality: 0.5)
                
                signUpButton.isEnabled = false
                print("🟢 2. Button Disabled, Calling ViewModel...")
                
                viewModel.performSignUp(
                    name: nameTextField.text,
                    email: emailTextField.text,
                    password: passwordTextField.text,
                    phone: phoneTextField.text,
                    role: self.userRole,
                    profileImage: imageData
                ) { [weak self] success, errorMessage in
                    
                    print("🟢 3. ViewModel Returned. Success: \(success)")
                    
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                                
                                
                                if success {
                                    print("✅ User Created Successfully as \(self.userRole)")
                                    
                                    AppNavigator.shared.navigateToRoleBasedHome(role: self.userRole)
                                    
                                } else {
                                    self.showAlert(title: "Sign Up Failed", message: errorMessage ?? "Unknown Error")
                                }
                            }
                }
        
    }
}



extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    


/// @Description: Performs the imagePickerController operation.
/// @Input: _ picker: UIImagePickerController; didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
/// @Output: Void
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
            profileImageView.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
            profileImageView.image = originalImage
        }
        
        picker.dismiss(animated: true)
    }
    


/// @Description: Performs the imagePickerControllerDidCancel operation.
/// @Input: _ picker: UIImagePickerController
/// @Output: Void
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}



extension SignUpViewController {
    


/// @Description: Performs the showAlert operation.
/// @Input: title: String; message: String
/// @Output: Void
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
   
    
  
}
