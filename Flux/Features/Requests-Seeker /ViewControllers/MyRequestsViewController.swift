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
    
    // Create the segmented control programmatically so we can return it in the header view
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
        switch currentState {
        case .pending: return pendingBookings.count
        case .inProgress: return inProgressBookings.count
        case .completed: return completedBookings.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! RequestTableCell
           
           let booking: Booking
           switch currentState {
           case .pending: booking = pendingBookings[indexPath.row]
           case .inProgress: booking = inProgressBookings[indexPath.row]
           case .completed: booking = completedBookings[indexPath.row]
           }
           
           // Populate Cell
           cell.serviceTitleLabel.text = booking.serviceTitle
           // cell.providerNameLabel.text = ... (Add this later)
           
           // Styling
           if currentState == .pending {
               cell.serviceImgView.layer.cornerRadius = 12
           } else {
               cell.serviceImgView.layer.cornerRadius = 30
           }
           
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
            let delete = UIContextualAction(style: .destructive, title: nil) { (_, _, completion) in
                self.showDeleteAlert(at: indexPath)
                completion(true)
            }
            delete.image = UIImage(systemName: "trash.fill")
            
            let settings = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                completion(true)
            }
            settings.backgroundColor = .systemOrange
            settings.image = UIImage(systemName: "gearshape.fill")
            
            return UISwipeActionsConfiguration(actions: [delete, settings])
        } else if currentState == .completed {
            let reviewAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                self.performSegue(withIdentifier: "goToReview", sender: self)
                completion(true)
            }
            reviewAction.image = UIImage(systemName: "star.fill")
            reviewAction.backgroundColor = .systemYellow // Yellow button from design
            
            let settingsAction = UIContextualAction(style: .normal, title: nil) { (_, _, _) in }
            settingsAction.image = UIImage(systemName: "gearshape.fill")
            settingsAction.backgroundColor = .systemGreen
            
            return UISwipeActionsConfiguration(actions: [reviewAction, settingsAction])
        }
        
        return nil
    }

    func showDeleteAlert(at indexPath: IndexPath) {
            let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to delete your request?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                
                // 1. Get the booking object
                let bookingToDelete = self.pendingBookings[indexPath.row]
                
                // 2. Ensure it has an ID
                guard let bookingId = bookingToDelete.id else { return }
                
                // 3. Call Repository to Delete from Firestore
                BookingRepository.shared.deleteBooking(id: bookingId) { result in
                    switch result {
                    case .success:
                        print("Booking deleted from database")
                        
                        // 4. Update UI (Main Thread)
                        DispatchQueue.main.async {
                            // Remove from the new array 'pendingBookings'
                            self.pendingBookings.remove(at: indexPath.row)
                            
                            // Also remove from master array to keep sync
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
        guard let seekerId = Auth.auth().currentUser?.uid else { return }
        
        BookingRepository.shared.fetchBookingsForSeeker(seekerId: seekerId, status: nil) { result in
            switch result {
            case .success(let bookings):
                // 1. Clear all lists
                self.allPendingBookings.removeAll()
                self.allInProgressBookings.removeAll()
                self.allCompletedBookings.removeAll()
                
                // 2. Sort into Master lists
                for booking in bookings {
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
                
                // 3. Update Display lists
                self.restoreAllData()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .failure(let error):
                print("Error fetching bookings: \(error)")
            }
        }
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


