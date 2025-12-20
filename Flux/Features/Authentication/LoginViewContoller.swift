//
//  LoginViewContoller.swift
//  Flux
//
//  Created by Ali Hussain Ali Alsaffar on 06/12/2025.
//


import UIKit
import FirebaseAuth

class LoginViewContoller: UIViewController {

    private let viewModel = AuthViewModel()
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        
        loginButton.isEnabled = false
        
        viewModel.performLogin(email: emailTextField.text, password: passwordTextField.text) { [weak self] success, errorMessage in
            
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loginButton.isEnabled = true
            }
            
            if success {
                self.navigateToHome()
            } else {
                self.showAlert(title: "Login Failed", message: errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    
    
}


extension LoginViewContoller {
    
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
        } else {
            showAlert(title: "Configuration Error", message: "HomeFeedViewController ID not found in Home.storyboard.")
        }
    }
    
    

}
