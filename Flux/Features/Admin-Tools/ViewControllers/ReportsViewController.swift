import UIKit

class ReportsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!

    struct Report {
        let subject: String
        let username: String
        let isReviewed: Bool
    }

    private let allReports: [Report] = [
        Report(subject: "Spamming Activity", username: "@suefgwi", isReviewed: false),
        Report(subject: "Fake Profile", username: "@john123", isReviewed: false),
        Report(subject: "Inappropriate Content", username: "@ali_dev", isReviewed: true),
        Report(subject: "Harassment", username: "@user99", isReviewed: true)
    ]

    private var filteredReports: [Report] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        segmentControl.selectedSegmentIndex = 0
        applyFilter()
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        applyFilter()
    }

    private func applyFilter() {
        let showReviewed = segmentControl.selectedSegmentIndex == 1
        filteredReports = allReports.filter {
            $0.isReviewed == showReviewed
        }
        tableView.reloadData()
    }
}

// MARK: - TableView DataSource
extension ReportsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        filteredReports.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReportCell",
            for: indexPath
        )

        let report = filteredReports[indexPath.row]

        cell.textLabel?.text = "Subject: \(report.subject)"
        cell.detailTextLabel?.text = report.username

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
        print("Selected:", filteredReports[indexPath.row])
    }
}
