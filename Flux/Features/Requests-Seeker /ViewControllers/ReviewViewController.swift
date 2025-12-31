//
//  File.swift
//  Flux
//
//  Created by Guest User on 31/12/2025.
//

import Foundation
import UIKit

class ReviewViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var providerImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var reviewTextView: UITextView!

    // Connect these 5 buttons from your Storyboard
    @IBOutlet var starButtons: [UIButton]!
    
    var currentRating: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        // Image Styling
        providerImageView.layer.cornerRadius = providerImageView.frame.height / 2
        providerImageView.clipsToBounds = true
        
        // Text Input Styling (Gray Backgrounds)
        titleTextField.backgroundColor = .systemGray6
        titleTextField.layer.cornerRadius = 8
        titleTextField.placeholder = "Title"
        
        reviewTextView.backgroundColor = .systemGray6
        reviewTextView.layer.cornerRadius = 8
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
        // Validation
        guard currentRating > 0 else {
            // Show alert: Please select a star rating
            return
        }
        
        // Navigate to Success Screen
        performSegue(withIdentifier: "goToSuccess", sender: self)
    }
}

// Helper to make TextView behave like TextField with placeholder
extension ReviewViewController: UITextViewDelegate {
    /**func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write your review"
            textView.textColor = .lightGray
        }
    }**/
}
