import UIKit

class ReportsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var SearchBar: UISearchBar!
    
    var viewModel: AdminToolsViewModel? = AdminToolsViewModel()
    
    private var allReports: [Report] = []   // original
    private var reports: [Report] = []      // filtered
    // Optional preloaded reports (set by previous VC to avoid loading after presentation)
    var initialReports: [Report]?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard tableView != nil else {
            print("ReportsViewController: tableView outlet is not connected.")
            return
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        // Make SearchBar access safe in case the outlet isn't connected
        SearchBar?.delegate = self
        if let sb = SearchBar {
            sb.placeholder = "Search reports"
            sb.autocapitalizationType = .none
        }

        // Make segment control access safe
        segmentControl?.setTitle("Open", forSegmentAt: 0)
        segmentControl?.setTitle("Reviewed", forSegmentAt: 1)
        if let sc = segmentControl {
            sc.selectedSegmentIndex = 0
            // ensure it sends events even if the storyboard action isn't connected
            sc.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        }

        // Use preloaded data if provided to avoid fetching after presentation
        if let prefetched = initialReports {
            allReports = prefetched
            // Apply current segment filter immediately
            updateDisplayedReports()
        } else {
            fetchReports()
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        // Apply the segment filter and preserve any search query
        SearchBar?.resignFirstResponder()
        updateDisplayedReports()
    }
    private func fetchReports() {
        guard let vm = viewModel else {
            print("ReportsViewController: viewModel is nil, cannot fetch reports")
            return
        }

        vm.fetchReports(filterStatus: nil) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.allReports = data
                    // Apply the currently selected segment + search filter
                    self?.updateDisplayedReports()
                case .failure(let error):
                    print("Fetch reports error:", error.localizedDescription)
                }
            }
        }
    }
    private func updateDisplayedReports() {
        let query = SearchBar?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Start from all reports, then apply segment filter (if available), then search
        var filtered = allReports

        if let sc = segmentControl {
            switch sc.selectedSegmentIndex {
            case 0:
                // 'New' -> open
                filtered = filtered.filter { $0.status.lowercased() == "open" }
            case 1:
                // 'Reviewed'
                filtered = filtered.filter { $0.status.lowercased() == "reviewed" }
            default:
                break
            }
        }

        if query.isEmpty {
            reports = filtered
        } else {
            let q = query.lowercased()
            reports = filtered.filter {
                let reason = $0.reason.lowercased()
                let reporter = $0.reporterId.lowercased()
                return reason.contains(q) || reporter.contains(q)
            }
        }

        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension ReportsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        reports.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReportCell",
            for: indexPath
        )

        let report = reports[indexPath.row]
        cell.textLabel?.text = "Reason: \(report.reason)"

        let statusRaw = report.status
        let statusLower = statusRaw.lowercased()
        let statusText: String
        let statusColor: UIColor
        switch statusLower {
        case "open":
            statusText = "Open"
            statusColor = .systemOrange
        case "reviewed":
            statusText = "Reviewed"
            statusColor = .systemGreen
        case "resolved":
            statusText = "Resolved"
            statusColor = .secondaryLabel
        default:
            statusText = statusRaw
            statusColor = .secondaryLabel
        }

        // Build attributed detail text: reporter (neutral) + colored status
        let reporterDisplay = report.reporterId
        let baseText = "Reporter: \(reporterDisplay) • Status: \(statusText)"
        let baseAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.secondaryLabel, .font: UIFont.systemFont(ofSize: 13)]
        let statusAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: statusColor, .font: UIFont.systemFont(ofSize: 13)]
        let attr = NSMutableAttributedString(string: baseText, attributes: baseAttrs)
        if let range = baseText.range(of: "Status: \(statusText)") {
            let nsRange = NSRange(range, in: baseText)
            attr.addAttributes(statusAttrs, range: nsRange)
        }
        cell.detailTextLabel?.attributedText = attr

        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)

        // Replace reporter id with readable username when available
        if let vm = viewModel {
            vm.fetchUserByIdentifier(report.reporterId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        if let current = tableView.cellForRow(at: indexPath) {
                            let reporter = "@\(user.username)"
                            let updated = "Reporter: \(reporter) • Status: \(statusText)"
                            let updatedAttr = NSMutableAttributedString(string: updated, attributes: baseAttrs)
                            if let r = updated.range(of: "Status: \(statusText)") {
                                let nsR = NSRange(r, in: updated)
                                updatedAttr.addAttributes(statusAttrs, range: nsR)
                            }
                            current.detailTextLabel?.attributedText = updatedAttr
                        }
                    case .failure:
                        // unable to resolve user - leave reporter id as-is
                        break
                    }
                }
            }
        }

        // Always allow navigation to report details so admins can view any report.
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.isUserInteractionEnabled = true

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ReportsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        let selected = reports[indexPath.row]

        if let vc = storyboard?.instantiateViewController(withIdentifier: "ReportViewController") as? ReportViewController {
            vc.reportID = selected.id
            vc.viewModel = viewModel
            if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension ReportsViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {

        // Let the shared update method handle filtering by segment + query
        updateDisplayedReports()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        updateDisplayedReports()
    }
}
