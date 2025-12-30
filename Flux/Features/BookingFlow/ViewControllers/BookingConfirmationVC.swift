import UIKit

class BookingConfirmationVC: UIViewController {

    // Connect this Label to the text that says "Booking #... has been Added"
    @IBOutlet weak var statusLabel: UILabel!
    
    // Variable to hold the ID passed from the previous screen
    var bookingID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update the label with the dynamic ID
        if !bookingID.isEmpty {
            statusLabel.text = "Booking #\(bookingID)\nhas been Added"
        }
    }
    
}
