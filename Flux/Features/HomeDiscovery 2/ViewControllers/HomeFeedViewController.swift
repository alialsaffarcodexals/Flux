import UIKit

class HomeFeedViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let viewModel = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Fetch only Services
        viewModel.fetchLiveServices { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (section, _) in
            if section == 0 { return self.createRecommendedSection() }
            if section == 1 { return self.createCategoriesSection() }
            return self.createServicesSection()
        }
    }

    private func createHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        header.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 0)
        return header
    }

    
    private func createRecommendedSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.7), heightDimension: .absolute(120))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 16, bottom: 20, trailing: 0)
        section.boundarySupplementaryItems = [self.createHeader()]
        return section
    }
    
    private func createCategoriesSection() -> NSCollectionLayoutSection {
        // 1. Set width to .estimated(100). This allows the pill to grow!
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(100),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // 2. The Group MUST also be .estimated(100)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(100),
            heightDimension: .absolute(38)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12 // Space between buttons
        
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16)
        section.boundarySupplementaryItems = [self.createHeader()]
        
        return section
    }
    
    private func createServicesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(220))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 15, trailing: 8)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(220))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)
        section.boundarySupplementaryItems = [self.createHeader()]
        return section
    }
    
}

// MARK: - DataSource & Delegate
extension HomeFeedViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 3 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 { return viewModel.categories.count }
        return viewModel.recommendedCompanies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecommendedCell", for: indexPath) as! RecommendedCell
            let company = viewModel.recommendedCompanies[indexPath.item]
            cell.containerView.backgroundColor = company.backgroundColor
            cell.serviceLabel.text = company.name     // Title
            cell.providerLabel.text = company.category // Subtitle
            return cell
            
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
            let category = viewModel.categories[indexPath.item]
            cell.configure(with: category, isSelected: indexPath.item == viewModel.selectedCategoryIndex)
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceCell", for: indexPath) as! ServiceCell
            let company = viewModel.recommendedCompanies[indexPath.item]
            
            // 1. LABELS: Title (Bold) = name, Subtitle (Gray) = category
            cell.titleLabel.text = company.name         // Shows "Math Tutoring (Algebra)"
            cell.providerLabel.text = company.category   // Shows "Lessons"
            cell.ratingLabel.text = "\(company.rating)"
            
            // 2. IMAGE FILL: This makes the photo look like the bag photo
            cell.serviceImageView.contentMode = .scaleAspectFill
            cell.serviceImageView.clipsToBounds = true
            
            // Load the image from the URL
            if !company.imageURL.isEmpty, let url = URL(string: company.imageURL) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data {
                        DispatchQueue.main.async {
                            cell.serviceImageView.image = UIImage(data: data)
                        }
                    }
                }.resume()
            } else {
                // Fallback if no image
                cell.serviceImageView.image = UIImage(systemName: "photo")
                cell.serviceImageView.contentMode = .center
                cell.serviceImageView.backgroundColor = .systemGray6
            }
            
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! SectionHeader
        header.titleLabel.textColor = .black
        header.titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        if indexPath.section == 0 { header.titleLabel.text = "Recommended" }
        else if indexPath.section == 1 { header.titleLabel.text = "Interests" }
        else { header.titleLabel.text = "All Services" }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            viewModel.selectedCategoryIndex = indexPath.item
            viewModel.filterBy(category: viewModel.categories[indexPath.item].name)
            DispatchQueue.main.async { self.collectionView.reloadData() }
        }
    }
}

