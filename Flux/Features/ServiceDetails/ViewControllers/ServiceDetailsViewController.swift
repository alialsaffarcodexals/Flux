//
//  ServiceDetailsViewController.swift
//  Flux
//
//  Created by Flux Agent on 02/01/2026.
//

import UIKit

class ServiceDetailsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var serviceImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var bookButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    
    // MARK: - Properties
    var viewModel: ServiceDetailsViewModel?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        guard let viewModel = viewModel else { return }
        
        nameLabel.text = viewModel.name
        descriptionLabel.text = viewModel.description
        
        // Image Loading
        if let url = viewModel.imageURL {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.serviceImageView.image = UIImage(data: data)
                    }
                }
            }
        } else {
            serviceImageView.image = UIImage(systemName: "photo")
            serviceImageView.contentMode = .center
        }
        
        // Styling
        serviceImageView.layer.cornerRadius = 12
        serviceImageView.clipsToBounds = true
        serviceImageView.contentMode = .scaleAspectFill
        
        // Button Styles are likely handled in Storyboard, but ensuring rounded corners here
        bookButton.layer.cornerRadius = 25
        bookButton.clipsToBounds = true
        messageButton.layer.cornerRadius = 25
        messageButton.clipsToBounds = true
    }

    // MARK: - Actions
    @IBAction func bookAppointmentTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Booking", bundle: nil)
        if let bookingVC = storyboard.instantiateViewController(withIdentifier: "BookingVC") as? RequestBookingViewController {
            // If data passing is needed: bookingVC.service = viewModel?.company
            navigationController?.pushViewController(bookingVC, animated: true)
        }
    }

    @IBAction func messageButtonTapped(_ sender: Any) {
        guard let providerId = viewModel?.providerId, !providerId.isEmpty else {
            print("❌ No Provider ID found for this service")
            return
        }
        
        // 1. Fetch Provider's Email
        ChatRepository.shared.fetchEmail(for: providerId) { [weak self] email in
            guard let self = self, let email = email else {
                print("❌ Could not find email for provider: \(providerId)")
                return
            }
            
            // 2. Get or Create Conversation
            ChatRepository.shared.getOrCreateConversation(otherUserEmail: email) { conversationId in
                guard let conversationId = conversationId else {
                    print("❌ Failed to get conversation ID")
                    return
                }
                
                // 3. Navigate to Chat Room
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
