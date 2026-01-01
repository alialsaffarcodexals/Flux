import UIKit

class NotificationCenterViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var NotificationTitle: UILabel!
    
    // MARK: - ViewModel
    private let viewModel = NotificationViewModel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTable()
        bindViewModel()
        // Ensure segment control sends events even if not connected in storyboard
        segmentControl?.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        // Ensure the current user's profile exists in Firestore first,
        // then fetch notifications/activities scoped to that user.
        viewModel.ensureCurrentUserRecord { [weak self] _ in
            DispatchQueue.main.async {
                self?.viewModel.fetchNotifications()
            }
        }
    }

    // MARK: - Setup
    private func setupUI() {
        segmentControl.removeAllSegments()
        segmentControl.insertSegment(withTitle: "Notifications", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: "Activities", at: 1, animated: false)
        segmentControl.selectedSegmentIndex = 0
        // Initial title label and nav title
        let initial = segmentControl.titleForSegment(at: segmentControl.selectedSegmentIndex) ?? "Notifications"
        NotificationTitle?.text = initial
        self.title = initial
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        // Ensure a cell is registered so dequeue doesn't fail. Use a basic registration
        // — we will create a `.subtitle` style cell as a fallback in `cellForRow`.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotificationCell")
    }

    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Apply current segment filter then reload
                let type: NotificationType = self.segmentControl.selectedSegmentIndex == 0 ? .notification : .activity
                self.viewModel.filter(by: type)
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Segment
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        let type: NotificationType = sender.selectedSegmentIndex == 0
            ? .notification
            : .activity
        // Update the UI title label and navigation title to reflect selection
        let titleText = sender.titleForSegment(at: sender.selectedSegmentIndex) ?? ""
        NotificationTitle?.text = titleText
        self.title = titleText
        viewModel.filter(by: type)
        tableView.reloadData()
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

        // Prefer dequeuing a registered cell; if the storyboard/prototype cell
        // is missing, fall back to a `.subtitle` UITableViewCell so detailTextLabel works.
        let dequeued = tableView.dequeueReusableCell(withIdentifier: "NotificationCell")
        let cell = dequeued ?? UITableViewCell(style: .subtitle, reuseIdentifier: "NotificationCell")

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
        // Instantiate and present the detail view controller programmatically
        // to avoid relying on a storyboard segue identifier.
        let sb = self.storyboard ?? UIStoryboard(name: "Activity", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "ViewNotificationViewController") as? ViewNotificationViewController {
            vc.notification = notification
            if let nav = self.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true, completion: nil)
            }
        }
    }
}
