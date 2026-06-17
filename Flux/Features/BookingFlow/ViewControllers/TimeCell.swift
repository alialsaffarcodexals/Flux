import UIKit

class TimeCell: UICollectionViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor.systemGray5.cgColor
    }
    }
