//
//  CompanyDetailsViewController.swift
//  Flux
//

import UIKit

class CompanyDetailsViewController: UIViewController {
    
    // MARK: - Properties
    var company: Company!
    
    // MARK: - Outlets (We will connect this later)
    @IBOutlet weak var companyLabel: UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the company name on the label
        companyLabel.text = company.name
    }
}
