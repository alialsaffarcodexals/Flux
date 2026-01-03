import UIKit
import Combine

class ServicePackagesListViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyStateView: UIView! // Assume this is connected in Storyboard
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // Add button is likely a UIBarButtonItem, but if it's a UIButton in view:
    // @IBOutlet weak var addButton: UIButton!
    
    // MARK: - Properties
    var viewModel: ServicePackagesListViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize VM if not injected (safe fallback)
        if viewModel == nil {
            viewModel = ServicePackagesListViewModel()
        }
        
        setupUI()
        bindViewModel()
        viewModel.loadPackages()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "My Service Packages"
        
        // Navigation Item
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPackageTapped(_:)))
        
        // Collection View Validation
         guard collectionView != nil else {
             print("CRITICAL: collectionView outlet is nil!")
             return
         }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ServicePackageCell.self, forCellWithReuseIdentifier: ServicePackageCell.identifier)
        
        // Layout
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 16
        let itemWidth = (view.bounds.width - (spacing * 3)) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.3) // Aspect ratio
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        collectionView.collectionViewLayout = layout
        
        // Initial state
        emptyStateView?.isHidden = true
        activityIndicator?.hidesWhenStopped = true
    }
    
    private func bindViewModel() {
        viewModel.$packages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] packages in
                self?.collectionView.reloadData()
                self?.emptyStateView?.isHidden = !packages.isEmpty
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator?.startAnimating()
                } else {
                    self?.activityIndicator?.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(message: message)
            }
            .store(in: &cancellables)
    }
    
    private func showAlert(message: String) {
        var displayMessage = message
        // Sanitize Firestore Index Error
        if message.contains("The query requires an index") {
            print("Firestore Index Error: \(message)") // Log the real error for debugging
            displayMessage = "Unable to load service packages. Please try again later."
        }
        
        let alert = UIAlertController(title: "Error", message: displayMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc @IBAction func addPackageTapped(_ sender: Any) {
        print("Add Package Tapped")
        guard let editorVC = AppNavigator.shared.getServicePackageEditorViewController(package: nil) else {
            print("Failed to instantiate ServicePackageEditorViewController")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            print("Pushing ServicePackageEditorViewController")
            self?.navigationController?.pushViewController(editorVC, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension ServicePackagesListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.packages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ServicePackageCell.identifier, for: indexPath) as? ServicePackageCell else {
            return UICollectionViewCell()
        }
        let package = viewModel.packages[indexPath.item]
        cell.configure(with: package)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let package = viewModel.packages[indexPath.item]
        if let editorVC = AppNavigator.shared.getServicePackageEditorViewController(package: package) {
            navigationController?.pushViewController(editorVC, animated: true)
        }
    }
}
