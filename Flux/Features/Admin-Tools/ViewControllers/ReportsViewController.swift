import UIKit

class ReportsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!

    private let viewModel = AdminToolsViewModel()
    private var reports: [Report] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        segmentControl.selectedSegmentIndex = 0
        fetchReports()
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        fetchReports()
    }

    private func fetchReports() {
        // segments: 0 -> Open, 1 -> Resolved
        let statusFilter = segmentControl.selectedSegmentIndex == 0 ? "Open" : "Resolved"

        viewModel.fetchReports(filterStatus: statusFilter) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.reports = data
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("❌ Fetch reports error:", error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - TableView DataSource
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
        cell.detailTextLabel?.text = "Reporter: \(report.reporterId)"

        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .secondaryLabel

        return cell
    }
}

// MARK: - TableView Delegate
extension ReportsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selected = reports[indexPath.row]
        if let vc = storyboard?.instantiateViewController(withIdentifier: "ReportViewController") as? ReportViewController {
            vc.reportID = selected.id
            vc.viewModel = viewModel
            navigationController?.pushViewController(vc, animated: true)
        } else {
            print("Selected report:", selected)
        }
    }
}
