import UIKit

class BookingConfirmationVC: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    var bookingID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        if !bookingID.isEmpty {
            statusLabel.text = "Booking #\(bookingID)\nhas been Added"
        }
    }
    
}
