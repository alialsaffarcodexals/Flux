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
    
    @IBAction func viewBookingTapped(_ sender: Any) {
        // 1. Capture the TabBarController reference BEFORE popping
        // Popping might detach this VC, making self.tabBarController nil
        var targetTabBar = self.tabBarController
        
        // Fallback: If nil, try to find it via window root
        if targetTabBar == nil {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController as? UITabBarController {
                targetTabBar = root
            }
        }
        
        // 2. Pop the navigation stack to root (cleanup Home tab)
        self.navigationController?.popToRootViewController(animated: false)
        
        // 3. Switch to the Requests tab (Index 1)
        targetTabBar?.selectedIndex = 1
    }
    
}
