import UIKit

class CategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView! // Add an ImageView to your cell in Storyboard if you can!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 18
        self.clipsToBounds = true
    }
    
    func configure(with category: CategoryData, isSelected: Bool) {
        categoryLabel.text = category.name
        
        // Makes it a perfect pill shape
        self.layer.cornerRadius = 19 // Half of the 38pt height
        self.clipsToBounds = true
        
        if isSelected {
            // --- SELECTED STATE: Solid Blue Background ---
            self.backgroundColor = UIColor.blueButtons
            categoryLabel.textColor = .black
            self.layer.borderWidth = 0
        } else {
            // --- DEFAULT STATE: Light Background ---
            self.backgroundColor = category.color // Your pastel color
            categoryLabel.textColor = .black
            self.layer.borderWidth = 1
            self.layer.borderColor = UIColor.systemGray5.cgColor
        }
    }
}
