/*
 File: HistoryVC.swift
 Purpose: View Controller for Service History screen
 Location: Features/History/ViewControllers/HistoryVC.swift
*/

import UIKit

class HistoryVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    private let viewModel = HistoryVM()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadHistory()
    }
    
    // MARK: - Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search history..."
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
        viewModel.toggleFavorite(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource
extension HistoryVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        
        guard let item = viewModel.item(at: indexPath.row) else {
            return cell
        }
        
        // Get elements by tag
        let profileImageView = cell.contentView.viewWithTag(100) as? UIImageView
        let topLabel = cell.contentView.viewWithTag(101) as? UILabel
        let bottomLabel = cell.contentView.viewWithTag(102) as? UILabel
        let favoriteButton = cell.contentView.viewWithTag(103) as? UIButton
        
        // Configure for History: Service name (top), Provider name (bottom)
        topLabel?.text = item.serviceName
        bottomLabel?.text = item.providerName
        
        // Configure favorite button
        let starImage = item.isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        favoriteButton?.setImage(starImage, for: .normal)
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
extension HistoryVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Navigate to provider detail if needed
    }
    
    // Swipe actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completionHandler in
            self?.viewModel.deleteItem(at: indexPath.row)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed
        
        // Favorite action
        let item = viewModel.item(at: indexPath.row)
        let favoriteAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completionHandler in
            self?.viewModel.toggleFavorite(at: indexPath.row)
            completionHandler(true)
        }
        favoriteAction.image = UIImage(systemName: item?.isFavorite == true ? "star.slash.fill" : "star.fill")
        favoriteAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, favoriteAction])
    }
}

// MARK: - UISearchBarDelegate
extension HistoryVC: UISearchBarDelegate {
    
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
