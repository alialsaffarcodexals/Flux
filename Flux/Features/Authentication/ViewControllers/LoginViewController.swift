/*
 File: LoginViewController.swift
 Purpose: class LoginViewContoller, extension LoginViewContoller, func showAlert
 Location: Features/Authentication/LoginViewController.swift
*/

















import UIKit


/// Class LoginViewContoller: Responsible for the lifecycle, state, and behavior related to LoginViewContoller.
class LoginViewContoller: UIViewController {

    private let viewModel = AuthViewModel()
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    private func setupBindings() {
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.showLoadingIndicator()
                } else {
                    self?.hideLoadingIndicator()
                }
            }
        }
    }
    

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        
        loginButton.isEnabled = false
            
            
            viewModel.performLogin(email: emailTextField.text, password: passwordTextField.text) { [weak self] success, errorMessage, user in
                
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loginButton.isEnabled = true
                    
                    if success, let user = user {
                        
                        
                        AppNavigator.shared.navigate(user: user)
                        
                    } else {
                        self.showAlert(title: "Login Failed", message: errorMessage ?? "An unknown error occurred.")
                    }
                }
            }
    }
    
    
    
}




extension LoginViewContoller {
    


/// @Description: Performs the showAlert operation.
/// @Input: title: String; message: String
/// @Output: Void
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    

    
   
    
    

}
