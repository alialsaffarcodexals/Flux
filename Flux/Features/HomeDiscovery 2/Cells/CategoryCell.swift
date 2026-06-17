import UIKit

class CategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Default styling
        self.layer.cornerRadius = 19
        self.clipsToBounds = true
    }
    
    func configure(with category: ServiceCategory, isSelected: Bool) {
        categoryLabel.text = category.name
        
        if isSelected {
            // --- SELECTED STATE ---
            // Assuming 'UIColor.blueButtons' is a custom extension you have.
            // If not, use .systemBlue or a specific color literal.
            self.backgroundColor = .systemBlue
            categoryLabel.textColor = .white
            self.layer.borderWidth = 0
        } else {
            // --- UNSELECTED STATE ---
            // ServiceCategory doesn't have a .color property from the DB yet.
            // So we use a default gray for now.
            self.backgroundColor = .systemGray6
            categoryLabel.textColor = .label
            self.layer.borderWidth = 1
            self.layer.borderColor = UIColor.systemGray5.cgColor
        }
    }
}
