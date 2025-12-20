import UIKit

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
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
                    role: "Seeker",
                    profileImage: imageData
                ) { [weak self] success, errorMessage in
                    
                    print("🟢 3. ViewModel Returned. Success: \(success)")
                    
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        self.signUpButton.isEnabled = true
                        print("🟢 4. Button Re-enabled")
                        
                        if success {
                            print("🟢 5. Navigating to Home")
                            self.navigateToHome()
                        } else {
                            print("🔴 6. Error Occurred: \(errorMessage ?? "N/A")")
                            self.showAlert(title: "Sign Up Failed", message: errorMessage ?? "Unknown Error")
                        }
                    }
                }
        
    }
}

extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension SignUpViewController {
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToHome() {
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        if let homeVC = homeStoryboard.instantiateViewController(withIdentifier: "HomeFeedViewController") as? HomeFeedViewController {
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return
            }
            
            window.rootViewController = homeVC
            UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromRight, animations: nil, completion: nil)
        }
    }
}
