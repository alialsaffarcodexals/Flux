//
//  RequestTableCell.swift
//  Flux
//
//  Created by BP-36-213-12 on 30/12/2025.
//

import UIKit

class RequestTableCell: UITableViewCell {
    @IBOutlet weak var serviceImgView: UIImageView!
    @IBOutlet weak var serviceTitleLabel: UILabel!
    @IBOutlet weak var providerNameLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!

    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        serviceImgView.layer.cornerRadius = serviceImgView.frame.height / 2
        serviceImgView.clipsToBounds = true
        serviceImgView.backgroundColor = UIColor.systemGray5
        
        // --- COMMENT OUT THESE LINES UNTIL YOU ADD THE BUTTON ---
                // let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
                // favoriteButton.setImage(UIImage(systemName: "star", withConfiguration: config), for: .normal)
                // favoriteButton.setImage(UIImage(systemName: "star.fill", withConfiguration: config), for: .selected)
                // favoriteButton.tintColor = .systemBlue
            
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
