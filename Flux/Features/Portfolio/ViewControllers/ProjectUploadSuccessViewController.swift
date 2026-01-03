//
//  ProjectUploadSuccessViewController.swift
//  Flux
//
//  Created by Guest User on 01/01/2026.
//

import UIKit

class ProjectUploadSuccessViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
    }
    
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if let nav = self.navigationController {
            nav.popToRootViewController(animated: true)
        }
        // 2. If it was presented modally, dismiss it and tell the parent to close
        else {
            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        }
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
