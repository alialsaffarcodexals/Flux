/// File: SignUpViewController.swift.
/// Purpose: Class SignUpViewController, func viewDidLoad, func setupUI, extension SignUpViewController, func imagePickerController, func imagePickerControllerDidCancel, extension SignUpViewController, func showAlert.
/// Location: Features/Authentication/SignUpViewController.swift.

import UIKit

/// Class SignUpViewController: Responsible for the lifecycle, state, and behavior related to SignUpViewController.
class SignUpViewController: UIViewController {

    private let viewModel = AuthViewModel()
    private var selectedImage: UIImage?

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editImageButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    /// Handles the view loading lifecycle.
    /// - Returns: Void.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    /// Sets up the user interface elements.
    /// - Returns: Void.
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
                    
        // Note: Added the user variable in the closure.
        viewModel.performSignUp(
            firstName: firstNameTextField.text,
            lastName: lastNameTextField.text,
            username: usernameTextField.text, // Added the username.
            email: emailTextField.text,
            password: passwordTextField.text,
            phone: phoneTextField.text,
            role: "Seeker",
            profileImage: imageData
        ) { [weak self] success, errorMessage, user in // Here we received the user
                
            print("🟢 3. ViewModel Returned. Success: \(success)")
                
            guard let self = self else { return }
                
            DispatchQueue.main.async {
                self.signUpButton.isEnabled = true
                        
                if success, let user = user { // Ensure that the user exists.
                    print("✅ User Created Successfully: \(user.name)")
                    
                    // Now the user variable is defined and can be passed.
                    AppNavigator.shared.navigate(user: user)
                    
                } else {
                    self.showAlert(title: "Sign Up Failed", message: errorMessage ?? "Unknown Error")
                }
            }
        }
    }
}

extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /// Handles the image picker finished picking media.
    /// - Parameters:
    ///   - picker: The UIImagePickerController instance.
    ///   - info: A dictionary containing the media information.
    /// - Returns: Void.
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
    
    /// Handles the image picker cancellation.
    /// - Parameter picker: The UIImagePickerController instance.
    /// - Returns: Void.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension SignUpViewController {
    
    /// Shows an alert with the provided title and message.
    /// - Parameters:
    ///   - title: The alert title.
    ///   - message: The alert message.
    /// - Returns: Void.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
