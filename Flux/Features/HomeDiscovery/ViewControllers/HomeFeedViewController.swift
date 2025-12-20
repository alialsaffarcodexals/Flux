import UIKit
import Combine

class HomeFeedViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover Services"
        bindViewModel()
        viewModel.fetchServices()
        viewModel.fetchRecommendations()
    }
    
    // MARK: - Bind ViewModel to UI
    private func bindViewModel() {
        viewModel.$allServices
            .receive(on: DispatchQueue.main)
            .sink { services in
                print("✅ Loaded \(services.count) services")
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showAlert(message: error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
