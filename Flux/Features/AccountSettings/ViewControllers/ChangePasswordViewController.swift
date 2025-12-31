import UIKit

class ChangePasswordViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmNewPasswordTextField: UITextField!
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var saveChangesButton: UIButton!
    
    // MARK: - Properties
    
    private let viewModel = ChangePasswordViewModel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        
        // Setup secure text entry
        newPasswordTextField.isSecureTextEntry = true
        confirmNewPasswordTextField.isSecureTextEntry = true
        currentPasswordTextField.isSecureTextEntry = true
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        viewModel.onLoadingChanged = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.showLoadingIndicator()
                    self?.saveChangesButton.isEnabled = false
                } else {
                    self?.hideLoadingIndicator()
                    self?.saveChangesButton.isEnabled = true
                }
            }
        }
        
        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.showAlert(title: "Error", message: message)
            }
        }
        
        viewModel.onSuccess = { 
            DispatchQueue.main.async {
                AppNavigator.shared.switchToAuthentication()
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - IBAction
    
    @IBAction func saveChangesTapped(_ sender: UIButton) {
        // Show confirmation alert
        let alert = UIAlertController(title: "Confirm", message: "Would you like to save your new password? You will be logged out.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            let startPassword = self.newPasswordTextField.text ?? ""
            let confirm = self.confirmNewPasswordTextField.text ?? ""
            let current = self.currentPasswordTextField.text ?? ""
            
            self.viewModel.submit(currentPassword: current, newPassword: startPassword, confirmPassword: confirm)
        }))
        
        present(alert, animated: true)
    }
}
