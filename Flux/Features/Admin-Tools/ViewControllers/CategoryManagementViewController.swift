import UIKit

class CategoryManagementViewController: UIViewController {

    enum Mode {
        case view
        case add
    }

    private var currentMode: Mode = .view

    @IBOutlet weak var addTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addTextFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var addTextFieldTop: NSLayoutConstraint!
    @IBOutlet weak var addTextFieldBottom: NSLayoutConstraint!
    
    private var categories: [(name: String, isEnabled: Bool)] = [
        ("AI & Machine Learning", true),
        ("Cybersecurity & Blockchain", true),
        ("Software & Mobile Development", true),
        ("Data Science & Analytics", true),
        ("Cloud & DevOps Engineering", false)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        addTextField.isHidden = true
        addTextField.delegate = self
        addTextFieldHeight.constant = 4
        addTextFieldTop.constant = 0
        addTextFieldBottom.constant = 0

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }

    // MARK: - Add Button
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        switch currentMode {
        case .view:
            enterAddMode()
        case .add:
            exitAddMode()
        }
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

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CategoryCell",
            for: indexPath
        )

        let item = categories[indexPath.row]

        // ✅ CLEAN reuse
        cell.accessoryView = nil
        cell.textLabel?.text = item.name
        cell.textLabel?.numberOfLines = 1
        cell.selectionStyle = .none

        // ✅ ONE switch per cell
        let toggle = UISwitch()
        toggle.isOn = item.isEnabled
        toggle.tag = indexPath.row
        toggle.addTarget(self,
                         action: #selector(categorySwitchChanged(_:)),
                         for: .valueChanged)

        cell.accessoryView = toggle
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryManagementViewController: UITableViewDelegate { }

// MARK: - Switch Action
extension CategoryManagementViewController {

    @objc private func categorySwitchChanged(_ sender: UISwitch) {
        categories[sender.tag].isEnabled = sender.isOn
    }
}

// MARK: - UITextFieldDelegate
extension CategoryManagementViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text,
              !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }

        categories.insert((text, true), at: 0)
        tableView.reloadData()
        exitAddMode()
        return true
    }
}
