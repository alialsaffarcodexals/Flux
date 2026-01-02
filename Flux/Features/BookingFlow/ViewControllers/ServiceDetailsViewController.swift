//
//  ServiceDetailsViewController.swift
//  Flux
//
//  Created by Faisal on 01/01/2026.
//

import Foundation

import UIKit
import FirebaseAuth

class ServiceDetailsViewController: UIViewController {

    // --- PROPERTIES ---
    // This is the specific UID you provided
    let providerUID = "Tv9bE9tfUKc5q3NsDQ4ePSJZt393"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    // --- ACTIONS ---
    @IBAction func messageButtonTapped(_ sender: Any) {
        
        // 1. Loading Indicator (Optional: You can add a spinner here)
        print("Looking up provider...")

        // 2. Get the Email for this UID
        ChatRepository.shared.fetchEmail(for: providerUID) { [weak self] email in
            guard let self = self, let providerEmail = email else {
                print("Error: Could not find provider email.")
                return
            }
            
            // 3. Get or Create the Chat ID
            ChatRepository.shared.getOrCreateConversation(otherUserEmail: providerEmail) { conversationId in
                guard let chatId = conversationId else { return }
                
                // 4. Navigate to Chat Room
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "goToChatRoom", sender: chatId)
                }
            }
        }
    }

    // --- NAVIGATION ---
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChatRoom" {
            if let destinationVC = segue.destination as? ChatRoomViewController {
                // Pass the ID we just found/created
                if let chatId = sender as? String {
                    destinationVC.conversationId = chatId
                }
            }
        }
    }
}
