import UIKit

class HomeFeedViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
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
            
            // 2. Set Data
            cell.titleLabel.text = service.title
            cell.providerLabel.text = service.category // Or service.providerId if you want
            
            if let rating = service.rating {
                cell.ratingLabel.text = String(format: "★ %.1f", rating)
            } else {
                cell.ratingLabel.text = "New"
            }
            
            // 3. Load Image
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
            
            // Only care about clicks in Section 1 (Categories)
            if indexPath.section == 1 {
                
                // 1. Update the selected index in ViewModel
                viewModel.selectedCategoryIndex = indexPath.item
                
                // 2. Get the category name
                let selectedCategory = viewModel.categories[indexPath.item]
                
                // 3. Trigger the Filter Logic
                viewModel.filterBy(category: selectedCategory.name)
                
                // 4. Reload Section 1 (to update Blue/Gray colors) AND Section 2 (to show filtered results)
                // Using reloadSections is smoother than reloadData()
                collectionView.reloadSections(IndexSet(integersIn: 1...2))
            }
        }
    
}
