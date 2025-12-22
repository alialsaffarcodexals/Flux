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
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    


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
                    
            // لاحظ إضافة المتغير user في الـ closure
        viewModel.performSignUp(
                    firstName: firstNameTextField.text,
                    lastName: lastNameTextField.text,
                    username: usernameTextField.text, // إضافة اليوزر نيم
                    email: emailTextField.text,
                    password: passwordTextField.text,
                    phone: phoneTextField.text,
                    role: "Seeker",
                    profileImage: imageData
                ) { [weak self] success, errorMessage, user in // 👈 هنا استقبلنا الـ user
                
                print("🟢 3. ViewModel Returned. Success: \(success)")
                
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.signUpButton.isEnabled = true
                            
                    if success, let user = user { // 👈 نتأكد أن الـ user موجود
                        print("✅ User Created Successfully: \(user.name)")
                        
                        // الآن المتغير user أصبح معرفاً ويمكن تمريره
                        AppNavigator.shared.navigate(user: user)
                        
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
