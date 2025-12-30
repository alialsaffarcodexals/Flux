//
//  ServiceCell.swift
//  Flux
//
//  Created by Mohammed on 24/12/2025.
//

import UIKit

class ServiceCell: UICollectionViewCell {

    // 1. OUTLETS
    // Ensure these are connected to your Storyboard (the circles on the left should be filled)
    @IBOutlet weak var serviceImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!

    // 2. SETUP
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Round the corners of the image slightly for a better look
        serviceImageView.layer.cornerRadius = 8
        
        // FORCE THE BUTTON IMAGES VIA CODE
        // This fixes the issue where the Storyboard doesn't update the icon
        favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)       // Hollow star
        favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .selected) // Filled star
        
        // Start with the button unselected (Hollow)
        favoriteButton.isSelected = false
    }

    // 3. ACTION
    @IBAction func favoriteButtonTapped(_ sender: UIButton) {
        // This toggles the state: If true -> becomes false. If false -> becomes true.
        sender.isSelected.toggle()
    }
}
