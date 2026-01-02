import UIKit

class NewPasswordViewController: UIViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    
    var email: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }
    
    @objc func confirmButtonTapped() {
        guard let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please enter and confirm your new password.")
            return
        }
        
        if password == confirmPassword {
            // MOCK IMPLEMENTATION
            // In a real app, since we are doing email/code verification, we would likely call a backend endpoint
            // or use Firebase's verifyPasswordResetCode + confirmPasswordReset.
            // But here we just simulate success as requested.
            print("Password updated for email: \(email ?? "Unknown")")
            
            showAlert(title: "Success", message: "Password reset successfully") {
                // Navigate back to Login
                self.navigationController?.popToRootViewController(animated: true)
            }
        } else {
            showAlert(title: "Error", message: "Passwords do not match")
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
