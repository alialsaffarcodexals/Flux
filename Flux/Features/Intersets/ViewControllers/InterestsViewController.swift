import UIKit

class InterestsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
    var viewModel = InterestsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interests"
        
        setupUI()
        setupBindings()
        viewModel.fetchCategories()
    }
    
    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        // Standard cell registration or prototype from storyboard
        // We will assume a prototype cell named "InterestCell" in storyboard
        tableView.tableFooterView = UIView()
    }
    
    private func setupBindings() {
        viewModel.onCategoriesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.showLoadingIndicator()
                } else {
                    self?.hideLoadingIndicator()
                }
            }
        }
        
        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.showAlert(title: "Error", message: message)
            }
        }
        
        viewModel.onSaveSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        viewModel.saveInterests()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension InterestsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InterestCell", for: indexPath)
        
        let category = viewModel.categories[indexPath.row]
        let isSelected = viewModel.isSelected(at: indexPath.row)
        
        cell.textLabel?.text = category.name
        // Show checkmark if selected
        cell.accessoryType = isSelected ? .checkmark : .none
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.toggleInterest(at: indexPath.row)
    }
}
