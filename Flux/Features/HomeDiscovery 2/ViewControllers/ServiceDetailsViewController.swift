import UIKit

class ServiceDetailsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var providerNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel! // Make sure Lines = 0 in Storyboard
    @IBOutlet weak var bookButton: UIButton!
    
    // MARK: - Data Variables
    var service: Service?
    var providerName: String? // We pass this from the Home Page
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateData()
    }
    
    func setupUI() {
        // Hide Tab Bar when entering details
        self.hidesBottomBarWhenPushed = true
        
        // Button Styling
        bookButton.layer.cornerRadius = 12
        bookButton.setTitle("Book Service", for: .normal)
        bookButton.backgroundColor = .systemBlue
        bookButton.setTitleColor(.white, for: .normal)
        
        // Image Styling
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
    }
    
    func populateData() {
        guard let service = service else { return }
        
        titleLabel.text = service.title
        priceLabel.text = "\(service.sessionPrice) \(service.currencyCode ?? "BHD")"
        descriptionLabel.text = service.description
        
        // Provider Name (Passed from previous screen)
        providerNameLabel.text = "Provided by \(providerName ?? "Unknown")"
        
        // Rating
        if let rating = service.rating {
            ratingLabel.text = "★ \(rating)"
        } else {
            ratingLabel.text = "New"
        }
        
        // Image Loading
        if let url = URL(string: service.coverImageURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.coverImageView.image = UIImage(data: data)
                    }
                }
            }
        } else {
            coverImageView.backgroundColor = .systemGray5
        }
    }

    // MARK: - Actions
    @IBAction func bookButtonTapped(_ sender: UIButton) {
        // TODO: Navigate to Booking Management / Calendar selection
        print("Navigate to Booking Flow for service: \(service?.id ?? "")")
        
        // Example:
        // let bookingVC = storyboard?.instantiateViewController(withIdentifier: "BookingVC") as! BookingViewController
        // bookingVC.service = service
        // navigationController?.pushViewController(bookingVC, animated: true)
    }
}
