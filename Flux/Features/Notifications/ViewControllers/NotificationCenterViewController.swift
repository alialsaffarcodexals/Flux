import UIKit

class NotificationCenterViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!

    // MARK: - ViewModel
    private let viewModel = NotificationViewModel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTable()
        bindViewModel()
        viewModel.fetchNotifications()
    }

    // MARK: - Setup
    private func setupUI() {
        segmentControl.removeAllSegments()
        segmentControl.insertSegment(withTitle: "Notifications", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: "Activities", at: 1, animated: false)
        segmentControl.selectedSegmentIndex = 0
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }

    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - Segment
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        let type: NotificationType = sender.selectedSegmentIndex == 0
            ? .notification
            : .activity

        viewModel.filter(by: type)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == "ShowNotificationDetails",
            let vc = segue.destination as? ViewNotificationViewController,
            let notification = sender as? Notification
        else { return }

        vc.notification = notification
    }
}

// MARK: - Table DataSource
extension NotificationCenterViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.count()
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NotificationCell",
            for: indexPath
        )

        let item = viewModel.notification(at: indexPath.row)

        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.fromName
        cell.accessoryType = .disclosureIndicator

        cell.textLabel?.font = item.isRead
            ? .systemFont(ofSize: 16)
            : .boldSystemFont(ofSize: 16)

        return cell
    }
}

// MARK: - Table Delegate
extension NotificationCenterViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = viewModel.notification(at: indexPath.row)
        viewModel.markAsRead(notification)
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowNotificationDetails", sender: notification)
    }
}
