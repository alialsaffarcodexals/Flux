import UIKit

class ProviderSetupViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var businessNameTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField! //
    @IBOutlet weak var bioTextView: UITextView!
    
    // MARK: - Properties
    private let viewModel = ProviderSetupViewModel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    // MARK: - Setup & Binding
    private func setupUI() {
        // Basic styling for the TextView
        bioTextView.layer.borderWidth = 1
        bioTextView.layer.borderColor = UIColor.systemGray5.cgColor
        bioTextView.layer.cornerRadius = 8
        
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
    }
    
    private func bindViewModel() {
        viewModel.onLoadingChanged = { [weak self] isLoading in
            if isLoading {
                self?.activityIndicator.startAnimating()
                self?.view.isUserInteractionEnabled = false
            } else {
                self?.activityIndicator.stopAnimating()
                self?.view.isUserInteractionEnabled = true
            }
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }

        viewModel.onSuccess = { user in
            print("✅ Provider Setup Complete. Routing via AppNavigator...")
            // The user object here now includes the new location
            AppNavigator.shared.navigate(user: user)
        }
    }

    // MARK: - Actions
    @IBAction func doneTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        viewModel.submitProviderSetup(
            businessName: businessNameTextField.text,
            location: locationTextField.text, //
            bio: bioTextView.text
        )
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Flux", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
