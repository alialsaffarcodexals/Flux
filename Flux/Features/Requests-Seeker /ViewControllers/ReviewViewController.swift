//
//  File.swift
//  Flux
//
//  Created by Guest User on 31/12/2025.
//

import Foundation
import UIKit
import FirebaseAuth

class ReviewViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var reviewContainerView: UIView!
    @IBOutlet weak var providerImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var titleContainerView: UIView!
        // Connect these 5 buttons from your Storyboard
    @IBOutlet var starButtons: [UIButton]!
    
    var bookingId: String = ""
    var serviceId: String = ""
    var providerId: String = ""
    var currentRating: Int = 0
    var providerName: String = ""
    var serviceName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
    }
    
    
    func setupUI() {
        // 1. Round Image
        providerImageView.layer.cornerRadius = providerImageView.frame.height / 2
        providerImageView.clipsToBounds = true
        
        // 2. Style the CONTAINERS (The Box Shape)
        titleContainerView.backgroundColor = .systemGray6
        titleContainerView.layer.cornerRadius = 12
        titleContainerView.clipsToBounds = true
        
        reviewContainerView.backgroundColor = .systemGray6
        reviewContainerView.layer.cornerRadius = 12
        reviewContainerView.clipsToBounds = true
        
        // 3. Style the INPUTS (Make them clear so they sit inside the box)
        titleTextField.backgroundColor = .clear
        titleTextField.borderStyle = .none
        titleTextField.textColor = .label
        
        reviewTextView.backgroundColor = .clear 
        reviewTextView.text = "Write your review"
        reviewTextView.textColor = .lightGray
        reviewTextView.delegate = self
    }
    // MARK: - TextView Delegate (The Placeholder Logic)
    
    // When user starts typing, remove the "placeholder" text
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.label // Default black/white color
        }
    }
    
    // When user stops typing, if empty, put "placeholder" back
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write your review"
            textView.textColor = UIColor.lightGray
        }
    }
    
    // Close keyboard when touching outside
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    // MARK: - Star Logic
    // Connect ALL 5 buttons to this ONE action in Storyboard
    // IMPORTANT: Set Tags in Storyboard: Button 1 -> Tag 1, Button 2 -> Tag 2, etc.
    @IBAction func starTapped(_ sender: UIButton) {
        let rating = sender.tag
        currentRating = rating
        updateStars(rating: rating)
    }
    
    func updateStars(rating: Int) {
        for button in starButtons {
            if button.tag <= rating {
                button.setImage(UIImage(systemName: "star.fill"), for: .normal)
                button.tintColor = .systemBlue
            } else {
                button.setImage(UIImage(systemName: "star"), for: .normal)
                button.tintColor = .systemGray
            }
        }
    }
    
    // MARK: - Navigation
    @IBAction func sendButtonTapped(_ sender: Any) {
        print("👆 Send Button Tapped!")
        // 1. Validation: Did they select a star?
        guard currentRating > 0 else {
            print("Please select a rating")
            return
        }
        
        // 2. Get Current User ID (Seeker)
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            return
        }
        
        // 3. Create the Review Object
        let newReview = Review(
            bookingId: bookingId,
            serviceId: serviceId,
            providerId: providerId,
            seekerId: currentUserId,
            rating: currentRating,
            comment: reviewTextView.text
        )
        
        print("🚀 Sending to Firestore...")
        
        // 4. ADD THIS: Send to Firestore using Repository
        ReviewRepository.shared.createReview(newReview) { result in
            switch result {
            case .success(let savedReview):
                print("✅ Review saved successfully! ID: \(savedReview.id ?? "Unknown")")
                
                // 5. Navigate to Success Screen on Main Thread
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "goToSuccess", sender: self)
                }
                
            case .failure(let error):
                print("❌ Error saving review: \(error.localizedDescription)")
                // Optional: Show an alert here telling the user it failed
                self.showAlert(message: "Failed to send: \(error.localizedDescription)")
            }
        }
        
        
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = "Write your review"
                textView.textColor = .lightGray
            }
        }
    }
    func showAlert(message: String) {
            let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        
        
    
}
