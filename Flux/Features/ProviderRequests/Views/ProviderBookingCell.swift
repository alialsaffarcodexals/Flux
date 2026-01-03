import UIKit
import CoreLocation

class ProviderBookingCell: UITableViewCell {
    
    enum CellMode {
        case request
        case upcoming
        case completed
    }
    
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
    
    func configure(with booking: Booking, mode: CellMode) {
        titleLabel.text = "\(booking.serviceTitle)"
        
        // Handle date formatting carefully to avoid crashes if date is missing (though model says non-optional)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: booking.scheduledAt)
        
        statusLabel.text = booking.status.rawValue.capitalized
        
        switch mode {
        case .request:
            actionStackView.isHidden = false
            acceptButton.isHidden = false
            rejectButton.isHidden = false
            acceptButton.setTitle("Accept", for: .normal)
            acceptButton.backgroundColor = .systemGreen
            rejectButton.setTitle("Reject", for: .normal)
            
        case .upcoming:
            actionStackView.isHidden = false
            acceptButton.isHidden = false
            rejectButton.isHidden = true
            acceptButton.setTitle("Completed", for: .normal)
            acceptButton.backgroundColor = .systemBlue
            
        case .completed:
            actionStackView.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func didTapAccept(_ sender: Any) {
        onAccept?()
    }
    
    @IBAction private func didTapReject(_ sender: Any) {
        onReject?()
    }
}
