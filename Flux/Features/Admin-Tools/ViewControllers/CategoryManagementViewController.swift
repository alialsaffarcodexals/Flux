//
//  ManageCategoryViewController.swift
//  Flux
//
//  Created by Ali Alkhozaae on 17/12/2025.
//

import UIKit

class CategoryManagementViewController: UIViewController {
    
    enum Mode {
        case view
        case add
    }

    private var currentMode: Mode = .view
    
    @IBOutlet weak var addTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        print("BUTTON TAPPED")
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
        addTextField.text = ""
        addTextField.becomeFirstResponder()
    }

    private func exitAddMode() {
        currentMode = .view
        addTextField.isHidden = true
        view.endEditing(true)
    }
    
}
