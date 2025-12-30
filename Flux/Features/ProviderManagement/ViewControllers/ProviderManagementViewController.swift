import UIKit

class ProviderManagementViewController: UIViewController {
    
    var viewModel = ProviderManagementViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Management"
    }
}
