import UIKit

class AdminToolsViewController: UIViewController {

    var viewModel: AdminToolsViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize ViewModel if not injected (simplifies storyboard entry)
        if viewModel == nil {
            viewModel = AdminToolsViewModel()
        }
        
        setupUI()
    }
    
    private func setupUI() {
        self.title = viewModel.title
        view.backgroundColor = .systemBackground
        print("🔧 Admin Dashboard Loaded")
    }
}
