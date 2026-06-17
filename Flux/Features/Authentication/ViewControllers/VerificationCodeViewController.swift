import UIKit

class VerificationCodeViewController: UIViewController {

    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var verifyButton: UIButton!
    
    public var email: String? // Stores the email passed from the previous screen
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        resendButton.addTarget(self, action: #selector(resendButtonTapped), for: .touchUpInside)
        verifyButton.addTarget(self, action: #selector(verifyButtonTapped), for: .touchUpInside)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "bQa-xs-ZPb" {
             // If this was triggered by button tap (and not code), we block it. 
             // Ideally we want to handle performSegue manually
             // Check logic in button tap
             guard let code = codeTextField.text, !code.isEmpty, code == "123456" else {
                 return false
             }
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "bQa-xs-ZPb",
           let destinationVC = segue.destination as? NewPasswordViewController {
            destinationVC.email = self.email
        }
    }
    
    @objc func resendButtonTapped() {
        showAlert(title: "Success", message: "Code has been sent again")
    }
    
    @objc func verifyButtonTapped() {
        guard let code = codeTextField.text, !code.isEmpty else {
            // This alert shows, but if the button is linked to segue, the segue logic triggers too. 
            // shouldPerformSegue handles blocking the segue if invalid.
            showAlert(title: "Error", message: "Please enter the code.")
            return
        }
        
        if code == "123456" {
             // If button is connected in storyboard, it performs segue automatically if shouldPerformSegue returns true.
             // We don't need to call performSegue manualy IF it is connected in storyboard.
             // BUT, if we want to show alert first? 
             // We can check storyboard connection. The XML showed button -> ID.
             // So manual performSegue causes double segue.
             // I will remove manual performSegue here relying on storyboard connection + shouldPerformSegue.
             // Wait, original prompt said "Action (Verify): ... If Match: Perform segue".
             // Since I kept storyboard connection, I should rely on that or remove connection.
             // I cannot remove connection easily.
             // So I will rely on storyboard connection.
        } else {
            showAlert(title: "Error", message: "Invalid Code")
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
