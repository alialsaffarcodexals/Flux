//
//  HomeFeedViewController.swift
//  Flux
//
//  Created by Mohammed on 24/12/2025.
//

import UIKit

class CompanyCell: UICollectionViewCell {
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyDescription: UILabel!
    @IBOutlet weak var companyBackgroundColorView: UIView!
    
}

class HomeFeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // 1. OUTLETS
    // matches the name in your old code so the connection stays safe
    @IBOutlet weak var recommendationsCollectionview: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var titleLabel: UILabel!
    
    // 2. VIEW MODEL
    var viewModel = HomeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the Collection View
        setupCollectionView()
        
        // Load the fake data from the ViewModel
        viewModel.loadDummyData()
        
        recommendationsCollectionview.reloadData()
    }
    
    func setupCollectionView() {
        // Assign the delegate and data source to "self" (this file)
        recommendationsCollectionview.dataSource = self
        recommendationsCollectionview.delegate = self
    }
    
    @IBAction func filterButtonClicked(_ sender: Any) {
        let vc = UIViewController()
        present(vc, animated: true)
    }
    
    // MARK: - Collection View Data Source

    // How many items to show? -> Count the services in our ViewModel
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.recommendedCompanies.count
    }

    // What does each cell look like?
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let company = viewModel.recommendedCompanies[indexPath.row]
        
        // Create (dequeue) the cell
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CompanyCell", for: indexPath) as? CompanyCell else {
            return UICollectionViewCell()
        }
        
        // Configure the cell with data
        cell.companyNameLabel.text = company.name
        cell.companyDescription.text = company.description
        cell.companyBackgroundColorView.backgroundColor = company.backgroundColor
        cell.companyBackgroundColorView.layer.cornerRadius = 10
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let company = viewModel.recommendedCompanies[indexPath.row]

        print("User pressed on company", company.name)
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        
        let companyDetailsVC = storyboard.instantiateViewController(identifier: "CompanyDetailsViewController") as! CompanyDetailsViewController
        
        companyDetailsVC.company = company
        
//        present(companyDetailsVC, animated: true)
        navigationController?.pushViewController(companyDetailsVC, animated: true)
    }
    
    // MARK: - Layout (Cell Size)
    
    // How big should each square be?
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Width: 160, Height: 200 (Matches your XIB design)
        return CGSize(width: 140, height: 100)
    }
}
