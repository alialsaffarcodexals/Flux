//
//  SuccessViewController.swift
//  Flux
//
//  Created by Guest User on 01/01/2026.
//

import UIKit

class SuccessViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let sheet = presentationController as? UISheetPresentationController {
        sheet.detents = [.medium()] // Takes up half the screen
        sheet.prefersGrabberVisible = true // Adds the little gray handle bar
        }
        // Do any additional setup after loading the view.
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
