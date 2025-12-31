import UIKit

final class PortfolioListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // Temporary data so table has something valid
    private var items: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Portfolio"

        // If you already connected delegate/dataSource in storyboard, this is still fine.
        tableView.dataSource = self
        tableView.delegate = self

        // If your prototype cell has NO identifier, use this fallback approach:
        // tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PortfolioCell")

        items = [] // start empty (no crash)
        tableView.reloadData()
    }
}

extension PortfolioListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // OPTION 1 (recommended): set prototype cell identifier in storyboard to "PortfolioCell"
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PortfolioCell") {
            cell.textLabel?.text = items[indexPath.row]
            return cell
        }

        // OPTION 2 (safe fallback if identifier not set)
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}
