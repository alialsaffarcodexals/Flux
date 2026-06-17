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
        servicesTableView.rowHeight = UITableView.automaticDimension
        servicesTableView.estimatedRowHeight = 80
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
        if let disputeVC = storyboard.instantiateViewController(withIdentifier: "DisputeCenterVC") as? DisputeCenterVC {
            if let company = viewModel?.company {
                disputeVC.providerToReport = (id: company.providerId, name: company.name)
            }
            navigationController?.pushViewController(disputeVC, animated: true)
        }
    }
    
    @IBAction func bookButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Booking", bundle: nil)
        if let bookingVC = storyboard.instantiateViewController(withIdentifier: "BookingVC") as? RequestBookingViewController {
            // Pass provider data via a constructed Service object
            if let company = viewModel?.company {
                let service = Service(
                    id: UUID().uuidString, // Validation might be needed later
                    providerId: company.providerId,
                    providerName: company.name,
                    title: "General Booking", // Or "Custom Booking"
                    description: "Booking with \(company.name)",
                    category: company.category,
                    sessionPrice: 0, // TBD
                    currencyCode: "BHD",
                    coverImageURL: company.imageURL,
                    rating: company.rating,
                    reviewCount: 0,
                    isActive: true,
                    createdAt: Date(),
                    updatedAt: nil
                )
                bookingVC.service = service
            }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ServiceCell")

        if let service = viewModel?.services[indexPath.row] {
            cell.textLabel?.text = service.title
            let priceText = String(format: "%.2f BHD", service.price)
            let descriptionText = service.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if descriptionText.isEmpty {
                cell.detailTextLabel?.text = priceText
            } else {
                cell.detailTextLabel?.text = "\(priceText) • \(descriptionText)"
            }
            cell.detailTextLabel?.numberOfLines = 2
            cell.selectionStyle = .none
            cell.imageView?.image = UIImage(systemName: "photo")
            cell.imageView?.tintColor = .systemGray3
            cell.imageView?.contentMode = .scaleAspectFill
            cell.imageView?.clipsToBounds = true

            cell.tag = indexPath.row
            if let urlString = service.coverImageUrl,
               let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    guard let data = data, let image = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        if cell.tag == indexPath.row {
                            cell.imageView?.image = image
                            cell.setNeedsLayout()
                        }
                    }
                }.resume()
            }
        }
        return cell
    }
}
