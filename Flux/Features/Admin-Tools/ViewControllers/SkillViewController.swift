import UIKit

class SkillViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var providerName: UILabel!
    @IBOutlet weak var providerUserName: UILabel!
    @IBOutlet weak var skillName: UILabel!
    @IBOutlet weak var skillLevel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadDummyData()
    }

    // MARK: - Dummy Data (for testing UI)
    private func loadDummyData() {
        providerName.text = "Ali Mohammed"
        providerUserName.text = "@sdklfh95"
        skillName.text = "Advance Plumbing"
        skillLevel.text = "Expert"
    }
}
