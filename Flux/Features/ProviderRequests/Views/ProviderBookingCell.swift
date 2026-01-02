import UIKit

class ProviderBookingCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var actionStackView: UIStackView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    // MARK: - Properties
    
    var onAccept: (() -> Void)?
    var onReject: (() -> Void)?
    
    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code if needed
        setupStyling()
    }
    
    private func setupStyling() {
        acceptButton.layer.cornerRadius = 8
        rejectButton.layer.cornerRadius = 8
    }

    // MARK: - Configuration
    
    func configure(with booking: Booking, showActions: Bool) {
        titleLabel.text = "\(booking.serviceTitle)"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: booking.scheduledAt)
        
        statusLabel.text = booking.status.rawValue.capitalized
        
        actionStackView.isHidden = !showActions
    }
    
    // MARK: - Actions
    
    @IBAction private func didTapAccept(_ sender: Any) {
        onAccept?()
    }
    
    @IBAction private func didTapReject(_ sender: Any) {
        onReject?()
    }
}
