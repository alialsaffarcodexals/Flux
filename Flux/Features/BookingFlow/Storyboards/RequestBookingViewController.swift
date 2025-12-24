//
//  RequestBookingViewController.swift
//  Flux
//
//  Created by Ali Hussain Ali Alsaffar on 06/12/2025.
//

import Foundation
import UIKit

class RequestBookingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var timeCollectionView: UICollectionView!
    @IBOutlet weak var servicesView: UIView!
    let hours = ["9:00 AM", "12:00 PM", "4:00 PM", "8:00 PM"]

    override func viewDidLoad() {
        super.viewDidLoad()
        timeCollectionView.dataSource = self
        timeCollectionView.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(goToServicesList))
            servicesView.addGestureRecognizer(tap)
            servicesView.isUserInteractionEnabled = true
        func openServicesPage() {
            if let servicesVC = storyboard?.instantiateViewController(withIdentifier: "Services TableVC") {
                self.navigationController?.pushViewController(servicesVC, animated: true)
            }
        }
        
    }
        @objc func goToServicesList() {
        if let destinationVC = storyboard?.instantiateViewController(withIdentifier: "ServicesTableVC") {
            self.navigationController?.pushViewController(destinationVC, animated: true)
        }
            
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hours.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeCell", for: indexPath) as! TimeCell
                cell.timeLabel.text = hours[indexPath.row]
                cell.timeLabel.textColor = .systemBlue
        
        return cell
        
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? TimeCell
        cell?.contentView.backgroundColor = .systemBlue
        cell?.timeLabel.textColor = .white
                let selectedTime = hours[indexPath.row]
        print("Selected time: \(selectedTime)")
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? TimeCell
        cell?.contentView.backgroundColor = UIColor.systemGray6
        cell?.timeLabel.textColor = .systemBlue
    }
    
    @IBOutlet weak var durationLabel: UILabel!
    var currentHours = 1
    
}
