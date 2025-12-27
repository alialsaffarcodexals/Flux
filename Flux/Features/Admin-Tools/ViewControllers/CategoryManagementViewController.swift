import UIKit

class CategoryManagementViewController: UIViewController {

    // MARK: - Mode
    enum Mode {
        case view
        case add
    }

    private var currentMode: Mode = .view

    // MARK: - Outlets
    @IBOutlet weak var addTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var addTextFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var addTextFieldTop: NSLayoutConstraint!
    @IBOutlet weak var addTextFieldBottom: NSLayoutConstraint!

    // MARK: - Data
    private var categories: [ServiceCategory] = []
    private let viewModel = AdminToolsViewModel()

    // MARK: - Loader
    private let loader = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTable()
        setupGesture()
        setupLoader()
        fetchCategories()
    }

    // MARK: - Setup
    private func setupUI() {
        title = viewModel.title

        addTextField.isHidden = true
        addTextField.delegate = self

        addTextFieldHeight.constant = 4
        addTextFieldTop.constant = 0
        addTextFieldBottom.constant = 0
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.isHidden = true
    }

    private func setupGesture() {
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        tableView.addGestureRecognizer(longPress)
    }

    private func setupLoader() {
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.hidesWhenStopped = true
        view.addSubview(loader)

        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Fetch Categories FIRST
    private func fetchCategories() {
        tableView.isHidden = true
        loader.startAnimating()

        viewModel.fetchCategories { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.loader.stopAnimating()

                switch result {
                case .success(let data):
                    self.categories = data
                    self.tableView.reloadData()
                    self.tableView.isHidden = false

                case .failure(let error):
                    print("❌ Fetch categories error:", error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Add Button
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        currentMode == .view ? enterAddMode() : exitAddMode()
    }

    private func enterAddMode() {
        currentMode = .add

        addTextField.isHidden = false
        addTextFieldHeight.constant = 34
        addTextFieldTop.constant = 16
        addTextFieldBottom.constant = 16

        addTextField.text = ""
        addTextField.becomeFirstResponder()

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func exitAddMode() {
        currentMode = .view

        addTextFieldHeight.constant = 4
        addTextFieldTop.constant = 0
        addTextFieldBottom.constant = 0
        addTextField.isHidden = true

        view.endEditing(true)

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource
extension CategoryManagementViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CategoryCell",
            for: indexPath
        )

        let category = categories[indexPath.row]

        cell.textLabel?.text = category.name
        cell.textLabel?.numberOfLines = 1
        cell.selectionStyle = .none
        cell.accessoryView = nil

        let toggle = UISwitch()
        toggle.isOn = category.isActive
        toggle.tag = indexPath.row
        toggle.addTarget(
            self,
            action: #selector(categorySwitchChanged(_:)),
            for: .valueChanged
        )

        cell.accessoryView = toggle
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryManagementViewController: UITableViewDelegate { }

// MARK: - Switch Action
extension CategoryManagementViewController {

    @objc private func categorySwitchChanged(_ sender: UISwitch) {
        let index = sender.tag
        let category = categories[index]

        guard let id = category.id else { return }

        categories[index].isActive = sender.isOn
        viewModel.updateCategoryStatus(
            categoryID: id,
            isActive: sender.isOn
        )
    }
}

// MARK: - UITextFieldDelegate
extension CategoryManagementViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard
            let text = textField.text,
            !text.trimmingCharacters(in: .whitespaces).isEmpty
        else { return false }

        viewModel.addCategory(name: text)
        exitAddMode()
        fetchCategories()
        return true
    }
}

// MARK: - Long Press Rename
extension CategoryManagementViewController {

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }

        let category = categories[indexPath.row]
        guard let id = category.id else { return }

        let alert = UIAlertController(
            title: "Rename Category",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { $0.text = category.name }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard
                let self = self,
                let newName = alert.textFields?.first?.text,
                !newName.trimmingCharacters(in: .whitespaces).isEmpty
            else { return }

            self.categories[indexPath.row].name = newName
            self.tableView.reloadRows(at: [indexPath], with: .automatic)

            self.viewModel.renameCategory(
                categoryID: id,
                newName: newName
            )
        })

        present(alert, animated: true)
    }
}
