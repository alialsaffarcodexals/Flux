//
//  PortfolioListViewController.swift
//  Flux
//
//  Created by Guest User on 01/01/2026.
//

import UIKit
import FirebaseAuth


class PortfolioListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    var projects: [PortfolioProject] = []
    override func viewDidLoad() {
         super.viewDidLoad()
         tableView.delegate = self
         tableView.dataSource = self
     }

     // 2. THIS IS THE KEY: Refresh data every time you come back to this screen
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Replace 'currentUserId' with your actual logic to get the logged-in user ID
        if let userId = Auth.auth().currentUser?.uid {
            PortfolioRepository.shared.fetchPortfolioProjects(providerId: userId) { result in
                switch result {
                case .success(let projects):
                    // Assuming you have a 'projects' array and 'tableView' outlet
                    self.projects = projects
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

     func fetchMyProjects() {
         guard let userId = Auth.auth().currentUser?.uid else { return }
         
         // 3. Use your shared Repository to get data
         PortfolioRepository.shared.fetchPortfolioProjects(providerId: userId) { result in
             switch result {
             case .success(let fetchedProjects):
                 // Update our list and reload the table
                 self.projects = fetchedProjects
                 DispatchQueue.main.async {
                     self.tableView.reloadData()
                 }
             case .failure(let error):
                 print("Error fetching projects: \(error.localizedDescription)")
             }
         }
     }

     // MARK: - TableView DataSource (Updated to use REAL data)
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return projects.count // Use the count of real projects
     }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "PortfolioCell", for: indexPath) as! PortfolioTableCell
         
         let project = projects[indexPath.row]
         
         // 4. Set the real data from Firebase
         cell.titleLabel.text = project.title
         
         // Format the date to look nice (e.g., "Jan 2026")
         let formatter = DateFormatter()
         formatter.dateFormat = "d MMM yyyy"
         cell.dateLabel.text = formatter.string(from: project.timestamp)
         
         // Use a library like Kingfisher or just a basic data task to load the image
         if let urlString = project.imageURLs.first, let url = URL(string: urlString) {
             // Basic way to load image (Better to use Kingfisher for a real app)
             URLSession.shared.dataTask(with: url) { data, _, _ in
                 if let data = data {
                     DispatchQueue.main.async {
                         cell.posterImageView.image = UIImage(data: data)
                     }
                 }
             }.resume()
         }
         
         return cell
     }
    
    // This is the "Exit Door" that other screens use to come back here
    @IBAction func unwindToPortfolio(segue: UIStoryboardSegue) {
        // This can stay empty. Its presence allows the "Done" button to work.
        print("Welcome back to Portfolio!")
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
