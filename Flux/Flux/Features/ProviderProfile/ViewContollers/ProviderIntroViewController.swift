import UIKit

class ProviderIntroViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func continueTapped(_ sender: UIButton) {
        // 1. Load the ProviderProfile Storyboard
        let storyboard = UIStoryboard(name: "ProviderProfile", bundle: nil)
        
        // 2. Instantiate the Setup VC safely
        if let setupVC = storyboard.instantiateViewController(withIdentifier: "ProviderSetupViewController") as? ProviderSetupViewController {
            
            // 3. Push it onto the stack
            self.navigationController?.pushViewController(setupVC, animated: true)
            
        } else {
            print("🔴 Error: Could not find 'ProviderSetupViewController' in ProviderProfile.storyboard")
        }
    }
}
