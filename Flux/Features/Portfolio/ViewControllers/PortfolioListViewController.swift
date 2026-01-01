//
//  PortfolioListViewController.swift
//  Flux
//
//  Created by Guest User on 01/01/2026.
//

import UIKit

class PortfolioListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup Large Title
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        //Setup Table
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - TableView DataSource
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 3 // Show 3 fake items
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // Make sure Identifier in Storyboard is "PortfolioCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: "PortfolioCell", for: indexPath) as! PortfolioTableCell
            
            // Fake Data Configuration
            if indexPath.row == 0 {
                cell.titleLabel.text = "Project: Fitness Tracker"
                cell.dateLabel.text = "17 Dec 2024"
                // cell.posterImageView.image = ... (Set a dummy image in storyboard to test)
            } else if indexPath.row == 1 {
                cell.titleLabel.text = "Project: Travel Planner"
                cell.dateLabel.text = "10 Jan 2025"
            } else {
                cell.titleLabel.text = "Project: Food Delivery"
                cell.dateLabel.text = "05 Feb 2025"
            }
            
            return cell
        }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
