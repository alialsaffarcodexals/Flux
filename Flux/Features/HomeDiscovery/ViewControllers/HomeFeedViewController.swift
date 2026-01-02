//
//  HomeFeedViewController.swift
//  Flux
//

import UIKit

// MARK: - Company Cell (Recommended - NO STAR)
class CompanyCell: UICollectionViewCell {
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyDescription: UILabel!
    @IBOutlet weak var companyBackgroundColorView: UIView!
    
    private var iconImageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupIconImageView()
    }
    
    private func setupIconImageView() {
        if iconImageView != nil { return }
        
        iconImageView = UIImageView()
        iconImageView?.contentMode = .scaleAspectFit
        iconImageView?.tintColor = .white
        iconImageView?.translatesAutoresizingMaskIntoConstraints = false
        
        guard let iconImageView = iconImageView else { return }
        companyBackgroundColorView.addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: companyBackgroundColorView.leadingAnchor, constant: 8),
            iconImageView.bottomAnchor.constraint(equalTo: companyBackgroundColorView.bottomAnchor, constant: -8),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with company: Company) {
        companyNameLabel?.text = company.name
        companyDescription?.text = company.description
        companyBackgroundColorView?.backgroundColor = company.backgroundColor
        companyBackgroundColorView?.layer.cornerRadius = 10
        iconImageView?.image = UIImage(systemName: company.iconName)
    }
}

// MARK: - Service Cell (VERTICAL grid - WITH star)
class ServiceCell: UICollectionViewCell {
    
    static let identifier = "ServiceCell"
    
    private var containerView: UIView!
    private var iconImageView: UIImageView!
    private var favoriteButton: UIButton!
    private var titleLabel: UILabel!
    private var providerLabel: UILabel!
    private var priceLabel: UILabel!
    private var ratingLabel: UILabel!
    
    var onFavoriteTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        containerView = UIView()
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        favoriteButton = UIButton(type: .system)
        favoriteButton.tintColor = .white
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        containerView.addSubview(favoriteButton)
        
        titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        providerLabel = UILabel()
        providerLabel.font = .systemFont(ofSize: 12)
        providerLabel.textColor = .secondaryLabel
        providerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(providerLabel)
        
        priceLabel = UILabel()
        priceLabel.font = .systemFont(ofSize: 13, weight: .medium)
        priceLabel.textColor = .systemBlue
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priceLabel)
        
        ratingLabel = UILabel()
        ratingLabel.font = .systemFont(ofSize: 12)
        ratingLabel.textColor = .secondaryLabel
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ratingLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 110),
            
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            favoriteButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 28),
            favoriteButton.heightAnchor.constraint(equalToConstant: 28),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            providerLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            providerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            priceLabel.topAnchor.constraint(equalTo: providerLabel.bottomAnchor, constant: 4),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            ratingLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    @objc private func favoriteTapped() {
        onFavoriteTapped?()
    }
    
    func configure(with service: ServiceItem) {
        containerView.backgroundColor = service.backgroundColor
        iconImageView.image = UIImage(systemName: service.iconName)
        titleLabel.text = service.name
        providerLabel.text = service.providerName
        priceLabel.text = "\(Int(service.price)) BHD"
        ratingLabel.text = "⭐ \(service.rating)"
        
        let starImage = service.isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: starImage), for: .normal)
    }
}

// MARK: - Home Feed View Controller
class HomeFeedViewController: UIViewController {

    @IBOutlet weak var recommendationsCollectionview: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var viewModel = HomeViewModel()
    var currentFilters = FilterOptions()
    var servicesCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.loadDummyData()
        setupRecommendationsCollectionView()
        setupServicesCollectionView()
    }
    
    func setupRecommendationsCollectionView() {
        recommendationsCollectionview.dataSource = self
        recommendationsCollectionview.delegate = self
        recommendationsCollectionview.tag = 1
        recommendationsCollectionview.reloadData()
    }
    
    func setupServicesCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 20, right: 16)
        
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 44) / 2
        layout.itemSize = CGSize(width: itemWidth, height: 190)
        
        servicesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        servicesCollectionView.backgroundColor = .clear
        servicesCollectionView.showsVerticalScrollIndicator = true
        servicesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        servicesCollectionView.dataSource = self
        servicesCollectionView.delegate = self
        servicesCollectionView.tag = 2
        
        servicesCollectionView.register(ServiceCell.self, forCellWithReuseIdentifier: ServiceCell.identifier)
        
        view.addSubview(servicesCollectionView)
        
        if let stackView = findPlaceholderStackView(in: view) {
            stackView.isHidden = true
            
            NSLayoutConstraint.activate([
                servicesCollectionView.topAnchor.constraint(equalTo: stackView.topAnchor),
                servicesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                servicesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                servicesCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                servicesCollectionView.topAnchor.constraint(equalTo: view.centerYAnchor),
                servicesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                servicesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                servicesCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
        
        servicesCollectionView.reloadData()
    }
    
    private func findPlaceholderStackView(in view: UIView) -> UIStackView? {
        for subview in view.subviews {
            if let stack = subview as? UIStackView {
                for arranged in stack.arrangedSubviews {
                    if arranged is UIStackView {
                        return stack
                    }
                }
            }
            if let found = findPlaceholderStackView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    // MARK: - Filter Button Action - PRESENT FROM BOTTOM
    @IBAction func filterButtonTapped(_ sender: Any) {
        print("🔥 Filter button tapped!")
        
        let filterVC = FilterViewController()
        filterVC.currentFilters = currentFilters
        
        filterVC.onFiltersApplied = { [weak self] filters in
            print("✅ Filters applied!")
            self?.currentFilters = filters
            self?.applyFilters()
        }
        
        // PRESENT FROM BOTTOM (slides up)
        filterVC.modalPresentationStyle = .pageSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = filterVC.sheetPresentationController {
                sheet.detents = [.large()]  // Full height
                sheet.prefersGrabberVisible = false
                sheet.preferredCornerRadius = 0
            }
        }
        
        present(filterVC, animated: true)
    }
    
    private func applyFilters() {
        viewModel.applyFilters(currentFilters)
        servicesCollectionView.reloadData()
        print("✅ Services reloaded with \(viewModel.services.count) items")
    }
}

// MARK: - Collection View Data Source
extension HomeFeedViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 {
            return viewModel.recommendedCompanies.count
        } else {
            return viewModel.services.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView.tag == 1 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CompanyCell", for: indexPath) as? CompanyCell else {
                return UICollectionViewCell()
            }
            let company = viewModel.recommendedCompanies[indexPath.row]
            cell.configure(with: company)
            return cell
            
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ServiceCell.identifier, for: indexPath) as? ServiceCell else {
                return UICollectionViewCell()
            }
            let service = viewModel.services[indexPath.row]
            cell.configure(with: service)
            cell.onFavoriteTapped = { [weak self] in
                self?.viewModel.toggleFavorite(at: indexPath.row)
                self?.servicesCollectionView.reloadItems(at: [indexPath])
            }
            return cell
        }
    }
}

// MARK: - Collection View Delegate
extension HomeFeedViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == 1 {
            let company = viewModel.recommendedCompanies[indexPath.row]
            print("Tapped company: \(company.name)")
            
            let storyboard = UIStoryboard(name: "Home", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "CompanyDetailsViewController") as! CompanyDetailsViewController
            vc.company = company
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let service = viewModel.services[indexPath.row]
            print("Tapped service: \(service.name)")
        }
    }
}

// MARK: - Collection View Flow Layout
extension HomeFeedViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView.tag == 1 {
            return CGSize(width: 140, height: 100)
        } else {
            let screenWidth = UIScreen.main.bounds.width
            let itemWidth = (screenWidth - 44) / 2
            return CGSize(width: itemWidth, height: 190)
        }
    }
}
