/*
 File: FavoritesVC.swift
 Purpose: View Controller for Favorites screen
 Location: Features/Favorites/ViewControllers/FavoritesVC.swift
*/

import UIKit

class FavoritesVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    private let viewModel = FavoritesVM()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
    }
    
    // MARK: - Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search favorites..."
    }
    
    private func bindViewModel() {
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.onError = { [weak self] error in
            self?.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func favoriteButtonTapped(_ sender: UIButton) {
        let point = sender.convert(CGPoint.zero, to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        viewModel.removeFromFavorites(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource
extension FavoritesVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoritesCell", for: indexPath)
        
        guard let item = viewModel.item(at: indexPath.row) else {
            return cell
        }
        
        // Get elements by tag
        let profileImageView = cell.contentView.viewWithTag(100) as? UIImageView
        let topLabel = cell.contentView.viewWithTag(101) as? UILabel
        let bottomLabel = cell.contentView.viewWithTag(102) as? UILabel
        let favoriteButton = cell.contentView.viewWithTag(103) as? UIButton
        
        // Configure for Favorites: Provider name (top), Service name (bottom)
        topLabel?.text = item.providerName
        bottomLabel?.text = item.serviceName
        
        // Configure favorite button (always filled in favorites)
        favoriteButton?.setImage(UIImage(systemName: "star.fill"), for: .normal)
        favoriteButton?.removeTarget(nil, action: nil, for: .allEvents)
        favoriteButton?.addTarget(self, action: #selector(favoriteButtonTapped(_:)), for: .touchUpInside)
        
        // Load profile image
        profileImageView?.layer.cornerRadius = 30
        profileImageView?.clipsToBounds = true
        if let urlString = item.profileImageURL, let url = URL(string: urlString) {
            loadImage(from: url, into: profileImageView)
        } else {
            profileImageView?.image = UIImage(systemName: "person.circle.fill")
            profileImageView?.tintColor = .systemGray3
        }
        
        return cell
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView?) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                imageView?.image = UIImage(data: data)
            }
        }.resume()
    }
}

// MARK: - UITableViewDelegate
extension FavoritesVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Navigate to provider detail if needed
    }
    
    // Swipe actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Remove from favorites action
        let removeAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completionHandler in
            self?.viewModel.removeFromFavorites(at: indexPath.row)
            completionHandler(true)
        }
        removeAction.image = UIImage(systemName: "star.slash.fill")
        removeAction.backgroundColor = .systemBlue
        
        // More options action
        let moreAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completionHandler in
            self?.showMoreOptions(for: indexPath.row)
            completionHandler(true)
        }
        moreAction.image = UIImage(systemName: "ellipsis")
        moreAction.backgroundColor = .systemGray
        
        return UISwipeActionsConfiguration(actions: [removeAction, moreAction])
    }
    
    private func showMoreOptions(for index: Int) {
        guard let item = viewModel.item(at: index) else { return }
        
        let alert = UIAlertController(title: item.providerName, message: "What would you like to do?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "View Profile", style: .default) { _ in
            // Navigate to profile
        })
        
        alert.addAction(UIAlertAction(title: "Remove from Favorites", style: .destructive) { [weak self] _ in
            self?.viewModel.removeFromFavorites(at: index)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension FavoritesVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        viewModel.clearSearch()
        searchBar.resignFirstResponder()
    }
}
