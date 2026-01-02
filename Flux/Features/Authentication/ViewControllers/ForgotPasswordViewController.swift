import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    
    var isEmailValid = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Basic UI setup if needed
        sendCodeButton.layer.cornerRadius = 8
        sendCodeButton.addTarget(self, action: #selector(sendCodeButtonTapped), for: .touchUpInside)
    }
    
    @objc func sendCodeButtonTapped() {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email.")
            return
        }
        
        // Disable button to prevent double tap
        sendCodeButton.isEnabled = false
        
        UserRepository.shared.checkEmailExists(email: email) { [weak self] result in
            DispatchQueue.main.async {
                self?.sendCodeButton.isEnabled = true
                
                switch result {
                case .success(let exists):
                    if exists {
                        self?.showAlert(title: "Success", message: "Message has been sent") {
                            // Manual Navigation
                            let storyboard = UIStoryboard(name: "Authentication", bundle: nil)
                            if let vc = storyboard.instantiateViewController(withIdentifier: "VerificationCodeViewController") as? VerificationCodeViewController {
                                vc.email = email
                                self?.navigationController?.pushViewController(vc, animated: true)
                            }
                        }
                    } else {
                         self?.showAlert(title: "Error", message: "Please sign up if you don't have an account.")
                    }
                case .failure(let error):
                    self?.showAlert(title: "Error", message: "Could not verify email: \(error.localizedDescription)")
                }
            }
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
