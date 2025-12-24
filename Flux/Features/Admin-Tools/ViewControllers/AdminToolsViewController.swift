import UIKit

class AdminToolsViewController: UIViewController {

    // MARK: - Service Providers
    @IBOutlet weak var serviceProviders: UILabel!

    // MARK: - Skills
    @IBOutlet weak var skillsRejected: UILabel!
    @IBOutlet weak var skillsPending: UILabel!
    @IBOutlet weak var skillsApproved: UILabel!

    // MARK: - Booking
    @IBOutlet weak var bookingRejected: UILabel!
    @IBOutlet weak var bookingPending: UILabel!
    @IBOutlet weak var bookingApproved: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDashboard()
    }

    // MARK: - Setup

    private func setupDashboard() {
        loadServiceProviders()
        loadSkillsStats()
        loadBookingStats()
    }

    // MARK: - Mock Data Loaders
    // (Replace these later with API calls)

    private func loadServiceProviders() {
        let totalProviders = 754
        serviceProviders.text = "\(totalProviders)"
    }

    private func loadSkillsStats() {
        let rejected = 50
        let pending  = 24
        let approved = 500

        skillsRejected.text = "\(rejected)"
        skillsPending.text  = "\(pending)"
        skillsApproved.text = "\(approved)"
    }

    private func loadBookingStats() {
        let rejected = 500
        let pending  = 804
        let approved = 5040

        bookingRejected.text = "\(rejected)"
        bookingPending.text  = "\(pending)"
        bookingApproved.text = "\(approved)"
    }
}
