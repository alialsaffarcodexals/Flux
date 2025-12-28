//
//  HomeFeedViewController.swift
//  Flux
//
//  Created by Mohammed on 24/12/2025.
//

import UIKit

class HomeFeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // 1. OUTLETS
    // matches the name in your old code so the connection stays safe
    @IBOutlet weak var collectionview: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // 2. VIEW MODEL
    var viewModel = HomeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the fake data from the ViewModel
        viewModel.loadDummyData()
        
        // Setup the Collection View
        setupCollectionView()
    }
    
    func setupCollectionView() {
        // Assign the delegate and data source to "self" (this file)
        collectionview.dataSource = self
        collectionview.delegate = self
        
        // Register the XIB file you created earlier
        // IMPORTANT: The name "ServiceCell" must match your file name exactly
        let nib = UINib(nibName: "ServiceCell", bundle: nil)
        collectionview.register(nib, forCellWithReuseIdentifier: "ServiceCell")
    }

    // MARK: - Collection View Data Source

    // How many items to show? -> Count the services in our ViewModel
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.services.count
    }

    // What does each cell look like?
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get the specific service for this position
        let service = viewModel.services[indexPath.row]
        
        // Create (dequeue) the cell
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceCell", for: indexPath) as? ServiceCell else {
            return UICollectionViewCell()
        }
        
        // Configure the cell with data
        cell.titleLabel.text = service.title
        
        // Use a placeholder image for now (since we don't have real URL downloading yet)
        cell.serviceImageView.image = UIImage(systemName: "wrench.fill")
        cell.serviceImageView.tintColor = .lightGray
        
        return cell
    }
    
    // MARK: - Layout (Cell Size)
    
    // How big should each square be?
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Width: 160, Height: 200 (Matches your XIB design)
        return CGSize(width: 160, height: 200)
    }
}
