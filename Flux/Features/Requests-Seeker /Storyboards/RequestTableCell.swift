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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        serviceImgView.layer.cornerRadius = 12
        serviceImgView.clipsToBounds = true
        serviceImgView.backgroundColor = UIColor.systemGray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
