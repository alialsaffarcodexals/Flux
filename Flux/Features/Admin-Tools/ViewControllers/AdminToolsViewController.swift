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

    // Prefetch caches to be passed to destination VCs
    private var reportsCache: [Report]?
    private var usersCache: [User]?
    private var skillsCache: [Skill]?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize ViewModel if not injected (simplifies storyboard entry)
        if viewModel == nil {
            viewModel = AdminToolsViewModel()
        }

        setupDashboard()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh dashboard counts when returning to this screen
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
        serviceProviders?.text = "..."
        viewModel.fetchServiceProvidersCount { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let count):
                    self?.serviceProviders?.text = "\(count)"
                case .failure(let error):
                    self?.serviceProviders?.text = "—"
                    print("❌ Fetch providers error:", error.localizedDescription)
                }
            }
        }
    }

    private func loadSkillsStats() {
        skillsRejected?.text = "..."
        skillsPending?.text = "..."
        skillsApproved?.text = "..."

        viewModel.fetchSkillsStats { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    self?.skillsRejected?.text = "\(stats.rejected)"
                    self?.skillsPending?.text = "\(stats.pending)"
                    self?.skillsApproved?.text = "\(stats.approved)"
                case .failure(let error):
                    self?.skillsRejected?.text = "—"
                    self?.skillsPending?.text = "—"
                    self?.skillsApproved?.text = "—"
                    print("❌ Fetch skills error:", error.localizedDescription)
                }
            }
        }
    }

    private func loadBookingStats() {
        bookingRejected?.text = "..."
        bookingPending?.text = "..."
        bookingApproved?.text = "..."

        viewModel.fetchBookingStats { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    self?.bookingRejected?.text = "\(stats.rejected)"
                    self?.bookingPending?.text = "\(stats.pending)"
                    self?.bookingApproved?.text = "\(stats.approved)"
                case .failure(let error):
                    self?.bookingRejected?.text = "—"
                    self?.bookingPending?.text = "—"
                    self?.bookingApproved?.text = "—"
                    print("❌ Fetch bookings error:", error.localizedDescription)
                }
            }
        }
    }
    
    private func setupUI() {
        self.title = viewModel.title
        view.backgroundColor = .systemBackground
    }

    @IBAction private func notificationTapped(_ sender: Any) {
        // Open the Activity storyboard's initial view controller (NotificationCenter)
        let sb = UIStoryboard(name: "Activity", bundle: nil)
        guard let vc = sb.instantiateInitialViewController() else { return }

        if let nav = navigationController {
            if let incomingNav = vc as? UINavigationController {
                    if let root = incomingNav.viewControllers.first {
                    nav.pushViewController(root, animated: true)
                } else {
                    incomingNav.modalPresentationStyle = .fullScreen
                    present(incomingNav, animated: true, completion: nil)
                }
            } else {
                nav.pushViewController(vc, animated: true)
            }
        } else {
            if let incomingNav = vc as? UINavigationController {
                incomingNav.modalPresentationStyle = .fullScreen
                present(incomingNav, animated: true, completion: nil)
            } else {
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: true, completion: nil)
            }
        }
    }

    // Intercept show segues to prefetch data before presenting screens.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // Known segue ids from storyboard that lead to Reports, Users, Skills
        // - Reports: GOg-At-580
        // - Users: 6i7-Bk-UbU
        // - Skills (verification): nL5-vr-SZk
        if identifier == "GOg-At-580" {
            if reportsCache != nil { return true }
            // fetch reports then perform segue
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.center = view.center
            spinner.startAnimating()
            view.addSubview(spinner)

            viewModel.fetchReports(filterStatus: nil) { [weak self] result in
                DispatchQueue.main.async {
                    spinner.removeFromSuperview()
                    switch result {
                    case .success(let data):
                        self?.reportsCache = data
                        self?.performSegue(withIdentifier: identifier, sender: sender)
                    case .failure(let error):
                        print("❌ Prefetch reports error:", error.localizedDescription)
                    }
                }
            }

            return false
        }

        if identifier == "6i7-Bk-UbU" {
            if usersCache != nil { return true }
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.center = view.center
            spinner.startAnimating()
            view.addSubview(spinner)

            viewModel.fetchUsers() { [weak self] result in
                DispatchQueue.main.async {
                    spinner.removeFromSuperview()
                    switch result {
                    case .success(let data):
                        self?.usersCache = data
                        self?.performSegue(withIdentifier: identifier, sender: sender)
                    case .failure(let error):
                        print("❌ Prefetch users error:", error.localizedDescription)
                    }
                }
            }

            return false
        }

        if identifier == "nL5-vr-SZk" {
            if skillsCache != nil { return true }
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.center = view.center
            spinner.startAnimating()
            view.addSubview(spinner)

            viewModel.fetchSkills(filterStatus: nil) { [weak self] result in
                DispatchQueue.main.async {
                    spinner.removeFromSuperview()
                    switch result {
                    case .success(let data):
                        self?.skillsCache = data
                        self?.performSegue(withIdentifier: identifier, sender: sender)
                    case .failure(let error):
                        print("❌ Prefetch skills error:", error.localizedDescription)
                    }
                }
            }

            return false
        }

        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let reportsVC = segue.destination as? ReportsViewController {
            reportsVC.viewModel = viewModel
            if let cache = reportsCache {
                reportsVC.initialReports = cache
                reportsCache = nil
            }
        }

        if let usersVC = segue.destination as? UsersAccountsViewController {
            usersVC.viewModel = viewModel
            if let cache = usersCache {
                usersVC.initialUsers = cache
                usersCache = nil
            }
        }

        if let skillsVC = segue.destination as? SkillVerificationViewController {
            skillsVC.viewModel = viewModel
            if let cache = skillsCache {
                skillsVC.initialSkills = cache
                skillsCache = nil
            }
        }
    }
}
