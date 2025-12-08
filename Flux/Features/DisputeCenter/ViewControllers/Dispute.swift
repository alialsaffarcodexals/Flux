//
//  Dispute.swift
//  Flux
//
//  Created by BP-36-201-15 on 08/12/2025.
//
import UIKit

private weak var Reasons: UITableView!

final class ReportViewController: UIViewController, UITableViewDataSource {
    @IBOutlet private weak var reasons: UITableView!   // <-- now matches your table’s name
    
    private let list = [
        "Inappropriate content",
        "Spam",
        "Harassment",
        "Scam / fraud",
        "Other"
    ]
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int { list.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: ip)
        cell.textLabel?.text = list[ip.row]
        return cell
    }
}

import Foundation
