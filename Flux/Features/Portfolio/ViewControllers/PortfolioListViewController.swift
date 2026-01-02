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
         
         // Format the date
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
         cell.onDeleteTap = { [weak self] in
             self?.showDeleteConfirmation(for: project)
         }
         return cell
     }
    
    // 4. ADD THE DELETE LOGIC FUNCTIONS
    func showDeleteConfirmation(for project: PortfolioProject) {
        guard let projectId = project.id else { return }

        let alert = UIAlertController(title: "Delete Project", message: "Are you sure you want to delete '\(project.title)'?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.performDeletion(projectId: projectId)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    func performDeletion(projectId: String) {
        // Call the Repository function you already have!
        PortfolioRepository.shared.deletePortfolioProject(id: projectId) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    // THE FIX: Find the CURRENT index of this project in the array
                    if let currentIndex = self.projects.firstIndex(where: { $0.id == projectId }) {
                        
                        // 1. Remove from local list using the fresh index
                        self.projects.remove(at: currentIndex)
                        
                        // 2. Animate the deletion using the fresh index
                        let indexPath = IndexPath(row: currentIndex, section: 0)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        
                        print("Successfully deleted project at index: \(currentIndex)")
                    } else {
                        // If it wasn't found in the array, just reload everything to be safe
                        self.tableView.reloadData()
                    }
                }
            case .failure(let error):
                print("Delete failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    
    
 

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAddProject",
           let destination = segue.destination as? AddProjectViewController,
           let project = sender as? PortfolioProject {
            
            // Pass the WHOLE object. The ID is inside it.
            destination.editingProject = project
            
            // Fill the UI
            destination.loadViewIfNeeded()
            destination.projectNameTextField.text = project.title
            destination.descriptionTextView.text = project.description
            destination.descriptionTextView.textColor = .black
            destination.datePicker.date = project.timestamp
            
            // This 'fake' selectedImage ensures the validation passes during an edit
            // In a real app, you'd load the image from the URL here
            destination.selectedImage = UIImage(systemName: "photo")
        }
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
