//
//  MyRequestsViewController.swift
//  Flux
//
//  Created by BP-36-213-12 on 30/12/2025.
//

import UIKit

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
    
    // The "Master" lists
    let allPending = ["Home Deep Cleaning service", "Car Wash", "AC Repair"]
    let allInProgress = ["Hashim Sharaf", "English Teacher"]
    let allCompleted = ["Sam Altman", "CleanMax", "Plumbing"]
    
    // The "Display" lists (These change when searching)
    var pendingServices: [String] = []
    var inProgressServices: [String] = []
    var completedServices: [String] = []
    
    var currentState: RequestState = .pending

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pendingServices = allPending
        inProgressServices = allInProgress
        completedServices = allCompleted
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self

        // Setup Segmented Control Action
        segmentedControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Search Bar Logic
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // If search bar is empty, restore all data
        if searchText.isEmpty {
            restoreAllData()
        } else {
            // Filter the data based on the text
            pendingServices = allPending.filter { $0.lowercased().contains(searchText.lowercased()) }
            inProgressServices = allInProgress.filter { $0.lowercased().contains(searchText.lowercased()) }
            completedServices = allCompleted.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Dismiss keyboard when "Search" is tapped on keyboard
        searchBar.resignFirstResponder()
    }
    
    func restoreAllData() {
        pendingServices = allPending
        inProgressServices = allInProgress
        completedServices = allCompleted
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
        case .pending: return pendingServices.count
        case .inProgress: return inProgressServices.count
        case .completed: return completedServices.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! RequestTableCell
        
        switch currentState {
        case .pending:
            cell.serviceTitleLabel.text = pendingServices[indexPath.row]
            cell.providerNameLabel.text = "CleanMax"
            cell.serviceImgView.layer.cornerRadius = 12
        case .inProgress:
            cell.serviceTitleLabel.text = inProgressServices[indexPath.row]
            cell.providerNameLabel.text = "Provider Info"
            cell.serviceImgView.layer.cornerRadius = 30
        case .completed:
            cell.serviceTitleLabel.text = completedServices[indexPath.row]
            cell.providerNameLabel.text = "Home Services"
            cell.serviceImgView.layer.cornerRadius = 30
        }
        
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
            
            // Add the green and orange buttons if needed to match design exactly
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
            self.pendingServices.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }))
        present(alert, animated: true)
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


