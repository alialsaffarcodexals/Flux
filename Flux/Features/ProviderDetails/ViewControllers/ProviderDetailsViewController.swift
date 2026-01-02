//
//  ProviderDetailsViewController.swift
//  Flux
//
//  Created by Flux Agent on 02/01/2026.
//

import UIKit

class ProviderDetailsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var providerImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var skillsStackView: UIStackView! // For MVP, we'll just add labels here
    @IBOutlet weak var servicesTableView: UITableView!
    @IBOutlet weak var bookButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    
    // MARK: - Properties
    var viewModel: ProviderDetailsViewModel?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        setupTableView()
        
        viewModel?.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
                self?.servicesTableView.reloadData()
            }
        }
        
        viewModel?.fetchServices()
    }
    
    private func setupUI() {
        guard let viewModel = viewModel else { return }
        
        // Image
        providerImageView.layer.cornerRadius = 50 // Assuming 100x100 size
        providerImageView.clipsToBounds = true
        providerImageView.contentMode = .scaleAspectFill
        if let url = viewModel.imageURL {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.providerImageView.image = UIImage(data: data)
                    }
                }
            }
        } else {
            providerImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        nameLabel.text = viewModel.name
        ratingLabel.text = viewModel.ratingText
        
        updateFavoriteIcon()
        
        // Buttons
        bookButton.layer.cornerRadius = 25
        bookButton.clipsToBounds = true
        messageButton.layer.cornerRadius = 25
        messageButton.clipsToBounds = true
        
        updateSkillsUI()
    }
    
    private func updateUI() {
        updateFavoriteIcon()
        updateSkillsUI()
    }
    
    private func updateSkillsUI() {
        // Clear existing skills
        skillsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard let viewModel = viewModel else { return }
        
        if viewModel.skills.isEmpty {
            let label = UILabel()
            label.text = "No skills available"
            label.font = .systemFont(ofSize: 14, weight: .regular)
            label.textColor = .secondaryLabel
            skillsStackView.addArrangedSubview(label)
        } else {
            viewModel.skills.forEach { skill in
                let label = UILabel()
                label.text = "  \(skill.name)  "
                label.font = .systemFont(ofSize: 12, weight: .medium)
                label.textColor = .white
                label.backgroundColor = .systemGray
                label.layer.cornerRadius = 10
                label.clipsToBounds = true
                skillsStackView.addArrangedSubview(label)
            }
        }
    }
    
    private func setupNavigation() {
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMenu))
        navigationItem.rightBarButtonItem = menuButton
    }
    
    private func setupTableView() {
        servicesTableView.delegate = self
        servicesTableView.dataSource = self
        servicesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ServiceCell")
    }
    
    private func updateFavoriteIcon() {
        // Only if we had a dedicated favorite button, but here it's in the menu.
        // We could change the menu icon or color if needed.
    }

    // MARK: - Actions
    
    @objc private func showMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let favoriteTitle = (viewModel?.isFavorite ?? false) ? "Remove from Favorites" : "Add to Favorites"
        alert.addAction(UIAlertAction(title: favoriteTitle, style: .default, handler: { _ in
            self.viewModel?.toggleFavorite()
        }))
        
        alert.addAction(UIAlertAction(title: "Report Provider", style: .destructive, handler: { _ in
            self.navigateToReport()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func navigateToReport() {
        let storyboard = UIStoryboard(name: "DisputeCenter", bundle: nil)
        if let disputeVC = storyboard.instantiateViewController(withIdentifier: "DisputeCenterVC") as? UIViewController {
            navigationController?.pushViewController(disputeVC, animated: true)
        }
    }
    
    @IBAction func bookButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Booking", bundle: nil)
        if let bookingVC = storyboard.instantiateViewController(withIdentifier: "BookingVC") as? UIViewController {
            navigationController?.pushViewController(bookingVC, animated: true)
        }
    }
    
    @IBAction func messageButtonTapped(_ sender: Any) {
        guard let providerId = viewModel?.providerId, !providerId.isEmpty else { return }
        
        ChatRepository.shared.fetchEmail(for: providerId) { [weak self] email in
            guard let self = self, let email = email else { return }
            
            ChatRepository.shared.getOrCreateConversation(otherUserEmail: email) { conversationId in
                guard let conversationId = conversationId else { return }
                
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "Chat", bundle: nil)
                    if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as? ChatRoomViewController {
                        chatVC.conversationId = conversationId
                        self.navigationController?.pushViewController(chatVC, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: - TableView DataSource
extension ProviderDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.services.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceCell", for: indexPath)
        if let service = viewModel?.services[indexPath.row] {
            cell.textLabel?.text = service.title
            cell.detailTextLabel?.text = "$\(service.price)"
        }
        return cell
    }
}
