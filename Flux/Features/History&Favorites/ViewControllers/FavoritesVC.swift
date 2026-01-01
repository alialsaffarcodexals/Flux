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
        tableView.register(FavoritesTableViewCell.self, forCellReuseIdentifier: "FavoritesCell")
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
        viewModel.removeFromFavorites(at: sender.tag)
    }
}

// MARK: - UITableViewDataSource
extension FavoritesVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FavoritesCell", for: indexPath) as? FavoritesTableViewCell,
              let item = viewModel.item(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        // Configure for Favorites: Provider name (top), Service name (bottom)
        cell.configure(
            topText: item.providerName,
            bottomText: item.serviceName,
            imageURL: item.profileImageURL
        )
        
        // Set up favorite button action
        cell.favoriteButton.tag = indexPath.row
        cell.favoriteButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped(_:)), for: .touchUpInside)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FavoritesVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Navigate to provider details
        guard let item = viewModel.item(at: indexPath.row) else { return }
        
        // TODO: Navigate to details screen
        // Example: performSegue(withIdentifier: "showProviderDetail", sender: item)
        print("Selected: \(item.providerName) - \(item.serviceName)")
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

// MARK: - Custom Cell
class FavoritesTableViewCell: UITableViewCell {
    
    let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let topLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let bottomLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "star.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        accessoryType = .disclosureIndicator
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(topLabel)
        contentView.addSubview(bottomLabel)
        contentView.addSubview(favoriteButton)
        
        let imageSize: CGFloat = 60
        
        NSLayoutConstraint.activate([
            // Profile image - left side
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: imageSize),
            profileImageView.heightAnchor.constraint(equalToConstant: imageSize),
            
            // Favorite button - right side (before disclosure indicator)
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favoriteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Top label
            topLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            topLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),
            topLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            
            // Bottom label
            bottomLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            bottomLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),
            bottomLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 4),
        ])
        
        profileImageView.layer.cornerRadius = imageSize / 2
    }
    
    func configure(topText: String, bottomText: String, imageURL: String?) {
        topLabel.text = topText
        bottomLabel.text = bottomText
        
        // Load image
        if let urlString = imageURL, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self?.profileImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        topLabel.text = nil
        bottomLabel.text = nil
    }
}
