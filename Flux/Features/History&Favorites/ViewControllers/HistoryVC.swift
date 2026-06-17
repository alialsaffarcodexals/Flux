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
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No services history available"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
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
        tableView.register(HistoryTableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        tableView.backgroundView = emptyStateLabel
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search history..."
    }
    
    private func bindViewModel() {
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
            self?.updateEmptyState()
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

    private func updateEmptyState() {
        let isEmpty = viewModel.itemCount == 0
        emptyStateLabel.isHidden = !isEmpty
        tableView.separatorStyle = isEmpty ? .none : .singleLine
    }
    
    // MARK: - Actions
    @objc private func favoriteButtonTapped(_ sender: UIButton) {
        viewModel.toggleFavorite(at: sender.tag)
    }
}

// MARK: - UITableViewDataSource
extension HistoryVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? HistoryTableViewCell,
              let item = viewModel.item(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        // Configure for History: Service name (top), Provider name (bottom)
        cell.configure(
            topText: item.serviceName,
            bottomText: item.providerName,
            imageURL: item.profileImageURL,
            isFavorite: item.isFavorite
        )
        
        // Set up favorite button action
        cell.favoriteButton.tag = indexPath.row
        cell.favoriteButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped(_:)), for: .touchUpInside)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HistoryVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Navigate to booking/provider details
        guard let item = viewModel.item(at: indexPath.row) else { return }
        
        // TODO: Navigate to details screen
        // Example: performSegue(withIdentifier: "showBookingDetail", sender: item)
        print("Selected: \(item.serviceName) - \(item.providerName)")
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

// MARK: - Custom Cell
class HistoryTableViewCell: UITableViewCell {
    
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
        button.setImage(UIImage(systemName: "star"), for: .normal)
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
    
    func configure(topText: String, bottomText: String, imageURL: String?, isFavorite: Bool) {
        topLabel.text = topText
        bottomLabel.text = bottomText
        
        // Update star
        let starImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        favoriteButton.setImage(starImage, for: .normal)
        
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
        favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
    }
}
