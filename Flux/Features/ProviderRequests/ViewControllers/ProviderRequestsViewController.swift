import UIKit
import Combine

class ProviderRequestsViewController: UIViewController {
    
    // MARK: - Properties
    
    var viewModel = ProviderRequestsViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    // UI Components
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    
    private var displayedBookings: [Booking] {
        return segmentedControl.selectedSegmentIndex == 0 ? viewModel.requests : viewModel.upcoming
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Requests"
        
        
        setupTableView()
        bindViewModel()
        
        viewModel.loadData()
    }
    
    private func setupTableView() {
        // Delegates are set in Storyboard
        // Refresh Control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    
    // MARK: - Setup
    
    // MARK: - Setup

    
    private func bindViewModel() {
        // Reload table when data changes
        viewModel.$requests
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.segmentedControl.selectedSegmentIndex == 0 {
                    self?.tableView.reloadData()
                    self?.tableView.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)
            
        viewModel.$upcoming
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.segmentedControl.selectedSegmentIndex == 1 {
                    self?.tableView.reloadData()
                    self?.tableView.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)
            
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @IBAction func didChangeSegment(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    @objc private func didPullToRefresh() {
        viewModel.loadData()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ProviderRequestsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedBookings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProviderBookingCell", for: indexPath) as? ProviderBookingCell else {
            return UITableViewCell()
        }
        
        let booking = displayedBookings[indexPath.row]
        let isRequest = segmentedControl.selectedSegmentIndex == 0
        
        cell.configure(with: booking, showActions: isRequest)
        
        cell.onAccept = { [weak self] in
            self?.viewModel.acceptBooking(booking)
        }
        
        cell.onReject = { [weak self] in
            self?.viewModel.rejectBooking(booking)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120 // Approximation
    }
}

