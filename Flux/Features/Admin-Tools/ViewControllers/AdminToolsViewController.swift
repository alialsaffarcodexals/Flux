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

    var viewModel: AdminToolsViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize ViewModel if not injected (simplifies storyboard entry)
        if viewModel == nil {
            viewModel = AdminToolsViewModel()
        }

        setupDashboard()
        setupUI()
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
        serviceProviders.text = "..."
        viewModel.fetchServiceProvidersCount { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let count):
                    self?.serviceProviders.text = "\(count)"
                case .failure(let error):
                    self?.serviceProviders.text = "—"
                    print("❌ Fetch providers error:", error.localizedDescription)
                }
            }
        }
    }

    private func loadSkillsStats() {
        skillsRejected.text = "..."
        skillsPending.text = "..."
        skillsApproved.text = "..."

        viewModel.fetchSkillsStats { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    self?.skillsRejected.text = "\(stats.rejected)"
                    self?.skillsPending.text = "\(stats.pending)"
                    self?.skillsApproved.text = "\(stats.approved)"
                case .failure(let error):
                    self?.skillsRejected.text = "—"
                    self?.skillsPending.text = "—"
                    self?.skillsApproved.text = "—"
                    print("❌ Fetch skills error:", error.localizedDescription)
                }
            }
        }
    }

    private func loadBookingStats() {
        bookingRejected.text = "..."
        bookingPending.text = "..."
        bookingApproved.text = "..."

        viewModel.fetchBookingStats { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    self?.bookingRejected.text = "\(stats.rejected)"
                    self?.bookingPending.text = "\(stats.pending)"
                    self?.bookingApproved.text = "\(stats.approved)"
                case .failure(let error):
                    self?.bookingRejected.text = "—"
                    self?.bookingPending.text = "—"
                    self?.bookingApproved.text = "—"
                    print("❌ Fetch bookings error:", error.localizedDescription)
                }
            }
        }
    }
    
    private func setupUI() {
        self.title = viewModel.title
        view.backgroundColor = .systemBackground
        print("🔧 Admin Dashboard Loaded")
    }
}
