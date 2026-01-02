import UIKit

class HomeFeedViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    // Use the new ViewModel we created
    let viewModel = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Setup Layout
        collectionView.collectionViewLayout = createLayout()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // 2. Fetch Data (Using the NEW function name)
        viewModel.fetchHomeData { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
                self?.updateEmptyState()
            }
        }
    }
    
    // MARK: - Compositional Layout
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (section, _) in
            if section == 0 { return self.createRecommendedSection() }
            if section == 1 { return self.createCategoriesSection() }
            return self.createServicesSection()
        }
    }
    
    func updateEmptyState() {
        // If we have services, hide the label. If 0, show it.
        let hasData = !viewModel.displayedServices.isEmpty
        
        self.emptyStateLabel.isHidden = hasData
        self.collectionView.isHidden = false // Keep collection view visible so we see headers
        
        if !hasData {
            self.emptyStateLabel.text = "No services found for this category."
        }
    }

    private func createHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        header.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)
        return header
    }

    // SECTION 0: Recommended (Providers/Companies)
    private func createRecommendedSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12)
        
        // Width 0.75 to show the next card peeking
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.75), heightDimension: .absolute(130))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 0)
        section.boundarySupplementaryItems = [self.createHeader()]
        return section
    }
    
    // SECTION 1: Categories (Pills)
    private func createCategoriesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // 2. The Group must ALSO use .estimated
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .absolute(40) // Fixed height for pills
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 10 // Space between pills
        
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16)
        section.boundarySupplementaryItems = [self.createHeader()]
        
        return section
    }
    
    // SECTION 2: Services (Grid)
    private func createServicesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(220))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 15, trailing: 8)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(220))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)
        // No header for grid, it sits under Categories
        return section
    }
}

// MARK: - DataSource & Delegate
extension HomeFeedViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return viewModel.recommendedProviders.count }
        if section == 1 { return viewModel.categories.count }
        return viewModel.displayedServices.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // SECTION 0: Recommended Companies (Providers)
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecommendedCell", for: indexPath) as! RecommendedCell
            
            // 1. Get the Provider (User struct)
            let provider = viewModel.recommendedProviders[indexPath.item]
            
            // 2. Set Data
            cell.companyLabel.text = provider.businessName ?? provider.name
            cell.descriptionLabel.text = provider.bio ?? "Professional Provider"
            cell.containerView.backgroundColor = viewModel.getRandomColor()
            
            return cell
            
        // SECTION 1: Categories
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
            
            let category = viewModel.categories[indexPath.item]
            
            let isSelected = (indexPath.item == viewModel.selectedCategoryIndex)
            cell.configure(with: category, isSelected: isSelected)
            
            return cell
            
        // SECTION 2: Services Grid
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceCell", for: indexPath) as! ServiceCell
            
            // 1. Get the Service (Service struct)
            let service = viewModel.displayedServices[indexPath.item]
            
            print(service)
            
            // 2. Set Data
            cell.titleLabel.text = service.title
            let name = viewModel.providerNames[service.providerId] ?? "Unknown Provider"

            cell.providerLabel.text = name
            
            if let rating = service.rating {
                cell.ratingLabel.text = String(format: "★ %.1f", rating)
            } else {
                cell.ratingLabel.text = "New"
            }
                        
            // 3. Load Image
            
            cell.serviceImageView.image = nil
            cell.serviceImageView.backgroundColor = .systemGray6
            if let url = URL(string: service.coverImageURL) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            cell.serviceImageView.image = UIImage(data: data)
                        }
                    }
                }
            } else {
                cell.serviceImageView.backgroundColor = .systemGray5
            }
            
            return cell
        }
    }

    // MARK: - Header Titles
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! SectionHeader
        
        if indexPath.section == 0 {
            header.titleLabel.text = "Recommended"
        } else if indexPath.section == 1 {
            header.titleLabel.text = "All Services"
        } else {
            header.titleLabel.text = ""
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            
        // Handle Category Selection
        if indexPath.section == 1 {
            
            // 1. Update the Model
            viewModel.selectedCategoryIndex = indexPath.item
            viewModel.filterBy(category: viewModel.categories[indexPath.item].name)
            DispatchQueue.main.async { self.collectionView.reloadData() }
        } else if indexPath.section == 0 {
            let provider = viewModel.recommendedProviders[indexPath.item]
            
            // Map User -> Company (Legacy Adapter)
            let company = Company(
                id: provider.id ?? UUID().uuidString,
                providerId: provider.id ?? "",
                name: provider.businessName ?? provider.name,
                description: provider.bio ?? "No description",
                backgroundColor: viewModel.getRandomColor(),
                category: "Provider",
                price: 0,
                rating: 5.0, // Placeholder
                dateAdded: Date(),
                imageURL: provider.providerProfileImageURL ?? ""
            )
            
            // Navigate to Provider Details
            let storyboard = UIStoryboard(name: "ProviderDetails", bundle: nil)
            if let providerVC = storyboard.instantiateViewController(withIdentifier: "ProviderDetailsVC") as? ProviderDetailsViewController {
                let providerViewModel = ProviderDetailsViewModel(company: company)
                providerVC.viewModel = providerViewModel
                navigationController?.pushViewController(providerVC, animated: true)
            }
        } else if indexPath.section == 2 {
            let service = viewModel.displayedServices[indexPath.item]
            
            // Map Service -> Company (Legacy Adapter)
            let company = Company(
                id: service.id ?? UUID().uuidString,
                providerId: service.providerId,
                name: service.title, // Maps to Title
                description: service.description,
                backgroundColor: viewModel.getRandomColor(),
                category: service.category,
                price: service.sessionPrice,
                rating: service.rating ?? 0.0,
                dateAdded: service.createdAt,
                imageURL: service.coverImageURL
            )
            
            // Navigate to Service Details
            let storyboard = UIStoryboard(name: "ServiceDetails", bundle: nil)
            if let detailsVC = storyboard.instantiateViewController(withIdentifier: "ServiceDetailsVC") as? ServiceDetailsViewController {
                let detailsViewModel = ServiceDetailsViewModel(company: company)
                detailsVC.viewModel = detailsViewModel
                navigationController?.pushViewController(detailsVC, animated: true)
            }
        }
    }
    
    // MARK: - Navigation Actions
    
    @IBAction func activityTapped(_ sender: Any) {
        // Open the Activity storyboard's initial view controller (NotificationCenter)
        let sb = UIStoryboard(name: "Activity", bundle: nil)
        guard let vc = sb.instantiateInitialViewController() else { return }

        if let nav = navigationController {
            if let incomingNav = vc as? UINavigationController {
                if let root = incomingNav.viewControllers.first {
                    nav.pushViewController(root, animated: true)
                } else {
                    incomingNav.modalPresentationStyle = .fullScreen
                    present(incomingNav, animated: true, completion: nil)
                }
            } else {
                nav.pushViewController(vc, animated: true)
            }
        } else {
            if let incomingNav = vc as? UINavigationController {
                incomingNav.modalPresentationStyle = .fullScreen
                present(incomingNav, animated: true, completion: nil)
            } else {
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: true, completion: nil)
            }
        }
    }
    
}
