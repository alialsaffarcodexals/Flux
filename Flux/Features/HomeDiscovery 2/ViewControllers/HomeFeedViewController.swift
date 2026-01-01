//
//  HomeFeedViewController.swift
//  Flux
//

import UIKit

// MARK: - Company Cell
class CompanyCell: UICollectionViewCell {
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyDescription: UILabel!
    @IBOutlet weak var companyBackgroundColorView: UIView!
    
}

// MARK: - Home Feed View Controller
class HomeFeedViewController: UIViewController {

    // MARK: - Outlets (We will connect these later)
    @IBOutlet weak var recommendationsCollectionview: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - Properties
    var viewModel = HomeViewModel()
    var currentFilters = FilterOptions()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        viewModel.loadDummyData()
        recommendationsCollectionview.reloadData()
    }
    
    // MARK: - Setup
    func setupCollectionView() {
        recommendationsCollectionview.dataSource = self
        recommendationsCollectionview.delegate = self
    }
    
    // MARK: - Filter Button Action (We will connect this later)
    @IBAction func filterButtonTapped(_ sender: Any) {
        let filterVC = FilterViewController()
        filterVC.currentFilters = currentFilters
        
        filterVC.onFiltersApplied = { [weak self] filters in
            self?.currentFilters = filters
            self?.applyFilters()
        }
        
        if let sheet = filterVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(filterVC, animated: true)
    }
    
    // MARK: - Apply Filters
    private func applyFilters() {
        viewModel.applyFilters(currentFilters)
        recommendationsCollectionview.reloadData()
    }
}

// MARK: - Collection View Data Source
extension HomeFeedViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.recommendedCompanies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let company = viewModel.recommendedCompanies[indexPath.row]
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CompanyCell", for: indexPath) as? CompanyCell else {
            return UICollectionViewCell()
        }
        
        cell.companyNameLabel.text = company.name
        cell.companyDescription.text = company.description
        cell.companyBackgroundColorView.backgroundColor = company.backgroundColor
        cell.companyBackgroundColorView.layer.cornerRadius = 10
        
        return cell
    }
}

// MARK: - Collection View Delegate
extension HomeFeedViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let company = viewModel.recommendedCompanies[indexPath.row]
        print("User tapped on: \(company.name)")
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let companyDetailsVC = storyboard.instantiateViewController(identifier: "CompanyDetailsViewController") as! CompanyDetailsViewController
        companyDetailsVC.company = company
        
        navigationController?.pushViewController(companyDetailsVC, animated: true)
    }
}

// MARK: - Collection View Flow Layout
extension HomeFeedViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 140, height: 100)
    }
}
