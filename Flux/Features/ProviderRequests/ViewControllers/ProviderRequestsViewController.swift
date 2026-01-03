import UIKit
import Combine

class ProviderRequestsViewController: UIViewController {
    
    // MARK: - Properties
    
    var viewModel = ProviderRequestsViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    
    private var displayedBookings: [Booking] {
        switch segmentedControl.selectedSegmentIndex {
        case 0: return viewModel.requests
        case 1: return viewModel.upcoming
        case 2: return viewModel.completed
        default: return []
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Requests"
        
        setupSegmentedControl()
        setupTableView()
        bindViewModel()
        
        viewModel.loadData()
    }
    
    private func setupSegmentedControl() {
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(withTitle: "Requests", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Upcoming", at: 1, animated: false)
        segmentedControl.insertSegment(withTitle: "Completed", at: 2, animated: false)
        segmentedControl.selectedSegmentIndex = 0
    }
    
    private func setupTableView() {
        // Delegates are set in Storyboard
        // Refresh Control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    
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
            
        viewModel.$completed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.segmentedControl.selectedSegmentIndex == 2 {
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
        let index = segmentedControl.selectedSegmentIndex
        
        // Determine mode
        let mode: ProviderBookingCell.CellMode
        switch index {
        case 0: mode = .request
        case 1: mode = .upcoming
        case 2: mode = .completed
        default: mode = .completed
        }
        
        cell.configure(with: booking, mode: mode)
        
        // Handle actions
        cell.onAccept = { [weak self] in
            if mode == .request {
                self?.viewModel.acceptBooking(booking)
            } else if mode == .upcoming {
                // In upcoming mode, primary action is COMPLETE
                self?.viewModel.completeBooking(booking)
            }
        }
        
        cell.onReject = { [weak self] in
            // Reject is only visible in request mode
            self?.viewModel.rejectBooking(booking)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120 // Approximation
    }
}

