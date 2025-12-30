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

class MyRequestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    // Data for each tab
    var pendingServices = ["Home Deep Cleaning service"]
    var inProgressServices = ["Hashim Sharaf", "English Teacher"]
    var completedServices = ["Sam Altman", "CleanMax"]
    
    var currentState: RequestState = .pending

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Listen for tab changes
        segmentedControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        
        tableView.tableFooterView = UIView()
    }

    @objc func tabChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: currentState = .pending
        case 1: currentState = .inProgress
        default: currentState = .completed
        }
        tableView.reloadData()
    }

    // MARK: - TableView Methods
    
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
            cell.serviceImgView.layer.cornerRadius = 12 // Square-ish
        case .inProgress:
            cell.serviceTitleLabel.text = inProgressServices[indexPath.row]
            cell.providerNameLabel.text = (indexPath.row == 0) ? "Filming" : "Private lesson"
            cell.serviceImgView.layer.cornerRadius = 30 // Circular
        case .completed:
            cell.serviceTitleLabel.text = completedServices[indexPath.row]
            cell.providerNameLabel.text = "Home Cleaning Services"
            cell.serviceImgView.layer.cornerRadius = 30 // Circular
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


