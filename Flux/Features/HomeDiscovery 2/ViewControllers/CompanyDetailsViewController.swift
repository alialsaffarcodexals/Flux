//
//  CompanyDetailsViewController.swift
//  Flux
//
//  Created by Musa Almatri on 30/12/2025.
//
import UIKit

class CompanyDetailsViewController: UIViewController {
  
    var company: Company!
    
    @IBOutlet weak var companyLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyLabel?.text = company?.name

    }
}
