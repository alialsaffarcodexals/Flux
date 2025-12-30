import UIKit

class ProviderRequestsViewController: UIViewController {
    
    var viewModel = ProviderRequestsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Requests"
    }
}
