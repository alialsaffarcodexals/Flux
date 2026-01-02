//
//  MyRequestsViewController.swift
//  Flux
//
//  Created by BP-36-213-12 on 30/12/2025.
//

import UIKit
import FirebaseAuth

// 1. Define the states outside the class
enum RequestState {
    case pending, inProgress, completed
}

class MyRequestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
            
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Create the segmented control programmatically
    let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Pending", "In Progress", "Completed"])
        sc.selectedSegmentIndex = 0
        return sc
    }()
    

    
    var pendingBookings: [Booking] = []
    var inProgressBookings: [Booking] = []
    var completedBookings: [Booking] = []

    // 2. Master Arrays (Backup for Search)
    var allPendingBookings: [Booking] = []
    var allInProgressBookings: [Booking] = []
    var allCompletedBookings: [Booking] = []
    
    var currentState: RequestState = .pending

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchBookings()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self

        // Setup Segmented Control Action
        segmentedControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Search Bar Logic
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            if searchText.isEmpty {
                restoreAllData()
            } else {
                // Filter by Service Title
                pendingBookings = allPendingBookings.filter { $0.serviceTitle.lowercased().contains(searchText.lowercased()) }
                inProgressBookings = allInProgressBookings.filter { $0.serviceTitle.lowercased().contains(searchText.lowercased()) }
                completedBookings = allCompletedBookings.filter { $0.serviceTitle.lowercased().contains(searchText.lowercased()) }
            }
            tableView.reloadData()
        }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Dismiss keyboard when "Search" is tapped on keyboard
        searchBar.resignFirstResponder()
    }
    
    func restoreAllData() {
            pendingBookings = allPendingBookings
            inProgressBookings = allInProgressBookings
            completedBookings = allCompletedBookings
        }

    // MARK: - Segment Control Logic
    @objc func tabChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: currentState = .pending
        case 1: currentState = .inProgress
        default: currentState = .completed
        }
    
        searchBar.text = ""
        searchBar.resignFirstResponder()
        restoreAllData()
        
        tableView.reloadData()
    }

    // MARK: - TableView Header (Sticky Segment)
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        headerView.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            segmentedControl.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10),
            segmentedControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }

    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            var count = 0
            
            
            switch currentState {
            case .pending:
                count = pendingBookings.count
                if count == 0 { setEmptyMessage("No Pending Requests") }
                
            case .inProgress:
                count = inProgressBookings.count
                if count == 0 { setEmptyMessage("No Requests In Progress") }
                
            case .completed:
                count = completedBookings.count
                if count == 0 { setEmptyMessage("No Completed Requests") }
            }
            
            
            if count > 0 {
                restoreBackground()
            }
            
            return count
        }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! RequestTableCell
            
            let booking: Booking
            switch currentState {
            case .pending: booking = pendingBookings[indexPath.row]
            case .inProgress: booking = inProgressBookings[indexPath.row]
            case .completed: booking = completedBookings[indexPath.row]
            }
            
            // 1. Text Data
            cell.serviceTitleLabel.text = booking.serviceTitle
            cell.providerNameLabel.text = booking.providerName 
            
            // 2. Image Logic
            cell.serviceImgView.image = nil
            cell.serviceImgView.backgroundColor = .systemGray5
            

            cell.serviceImgView.contentMode = .scaleAspectFill
            
            cell.serviceImgView.loadImage(from: booking.providerImageURL)
            
            cell.serviceImgView.layer.cornerRadius = 30
            
            cell.serviceImgView.clipsToBounds = true
            
            return cell
        }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    

    // MARK: - Swipe Actions
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            
            if currentState == .inProgress {
                let messageAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                    print("Open Chat")
                    completion(true)
                }
                messageAction.image = UIImage(systemName: "bubble.left.fill")
                messageAction.backgroundColor = .systemGreen
                return UISwipeActionsConfiguration(actions: [messageAction])
                
            } else if currentState == .pending {
                let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completion) in
                    self.showDeleteAlert(at: indexPath)
                    completion(true)
                }
                deleteAction.image = UIImage(systemName: "trash.fill")
                
                let settingsAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                    completion(true)
                }
                settingsAction.backgroundColor = .systemOrange
                settingsAction.image = UIImage(systemName: "gearshape.fill")
                
                return UISwipeActionsConfiguration(actions: [deleteAction, settingsAction])
                
            } else if currentState == .completed {
                        
                let booking = completedBookings[indexPath.row]
                
                let isAlreadyReviewed = booking.isReviewed ?? false
                
                if isAlreadyReviewed {
                    let seenAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                        
                        let alert = UIAlertController(title: "Reviewed", message: "You have already reviewed this request.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                        
                        completion(true)
                    }
                    seenAction.image = UIImage(systemName: "checkmark.seal.fill")
                    seenAction.backgroundColor = .systemBlue
                    
                    return UISwipeActionsConfiguration(actions: [seenAction])
                    
                } else {
                    let reviewAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                        self.performSegue(withIdentifier: "goToReview", sender: indexPath)
                        completion(true)
                    }
                    reviewAction.image = UIImage(systemName: "star.fill")
                    reviewAction.backgroundColor = .systemYellow
                    
                    let settingsAction = UIContextualAction(style: .normal, title: nil) { (_, _, _) in }
                    settingsAction.image = UIImage(systemName: "gearshape.fill")
                    settingsAction.backgroundColor = .systemGreen
                    
                    return UISwipeActionsConfiguration(actions: [reviewAction, settingsAction])
                }
            }
            
            return nil
        }

    func showDeleteAlert(at indexPath: IndexPath) {
            let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to delete your request?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                
                let bookingToDelete = self.pendingBookings[indexPath.row]
                
                guard let bookingId = bookingToDelete.id else { return }
                
                BookingRepository.shared.deleteBooking(id: bookingId) { result in
                    switch result {
                    case .success:
                        print("Booking deleted from database")
                        
                        DispatchQueue.main.async {
                            self.pendingBookings.remove(at: indexPath.row)
                            
                            self.allPendingBookings.removeAll { $0.id == bookingId }
                            
                            // Animate the row deletion
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                        
                    case .failure(let error):
                        print("Error deleting booking: \(error.localizedDescription)")
                    }
                }
            }))
            
            present(alert, animated: true)
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToReview" {
            let destVC = segue.destination as! ReviewViewController
            
            if let indexPath = sender as? IndexPath {
                // Get the booking from the Completed list
                let booking = completedBookings[indexPath.row]
                
                // Pass ALL necessary IDs to the Review Screen
                destVC.bookingId = booking.id ?? ""
                destVC.serviceId = booking.serviceId
                destVC.providerId = booking.providerId
                destVC.serviceName = booking.serviceTitle
                // destVC.providerName = ... (You need to fetch provider name separately or store it in booking)
            }
        }
    }
    func fetchBookings() {
        guard let currentUser = Auth.auth().currentUser else {
            print("🕵️ ERROR: No user is logged in!")
            return
        }
        
        let seekerId = currentUser.uid
        print("🕵️ I am searching for bookings with Seeker ID: \(seekerId)")
        
        BookingRepository.shared.fetchBookingsForSeeker(seekerId: seekerId, status: nil) { result in
            switch result {
            case .success(let bookings):
                print("🕵️ SUCCESS: Found \(bookings.count) bookings in Firestore.")
                
                // Clear all lists
                self.allPendingBookings.removeAll()
                self.allInProgressBookings.removeAll()
                self.allCompletedBookings.removeAll()
                
                // Sort into Master lists
                for booking in bookings {
                    print("   - Found Booking: \(booking.serviceTitle) | Status: \(booking.status.rawValue)")
                    
                    switch booking.status {
                    case .pending, .requested:
                        self.allPendingBookings.append(booking)
                    case .accepted, .inProgress:
                        self.allInProgressBookings.append(booking)
                    case .completed:
                        self.allCompletedBookings.append(booking)
                    default: break
                    }
                }
                
                // Update Display lists
                self.restoreAllData()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .failure(let error):
                print("🕵️ FAILURE: Error fetching bookings: \(error)")
            }
        }
    }
    
    // MARK: - navigation for sccesse
        @IBAction func unwindToRequests(segue: UIStoryboardSegue) {
            print("✅ Success! Returned to Request List.")
            
            // Refresh data so the button turns Blue
            fetchBookings()
        }
    // MARK: - Empty State Helper
        func setEmptyMessage(_ message: String) {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            messageLabel.text = message
            messageLabel.textColor = .secondaryLabel
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            messageLabel.sizeToFit()

            tableView.backgroundView = messageLabel
            tableView.separatorStyle = .none
        }

        func restoreBackground() {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


