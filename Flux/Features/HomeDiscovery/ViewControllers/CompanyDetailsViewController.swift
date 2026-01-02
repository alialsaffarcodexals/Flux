//
//  CompanyDetailsViewController.swift
//  Flux
//

import UIKit

class CompanyDetailsViewController: UIViewController {
    
    var company: Company!
    
    @IBOutlet weak var companyLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        companyLabel.text = company.name
    }
}
