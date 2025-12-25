//
//  Dispute.swift
//  Flux
//
//  Created by BP-36-201-15 on 08/12/2025.
//
import UIKit
import PhotosUI

final class ReportViewController: UIViewController, PHPickerViewControllerDelegate {
    
    // MARK: - model
    private let list = ["Inappropriate content", "Spam", "Harassment", "Scam / fraud", "Other"]
    private var selectedReason: String?
    @IBOutlet weak var reasonLabel: UILabel!
    private var selectedImage: UIImage?
    
    // MARK: - UI (already wired in storyboard/xib)
    
    @IBOutlet weak var reasonsTableView: UITableView!
    
    @IBOutlet weak var uploadPictureButton: UIButton!
    private let chooseButton = UIButton(type: .system)
    
    
    
    
    
    
    // MARK: - life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        
        setupChooseButton()
     
        print("button  frame:", chooseButton.frame)
        print("table   frame:", reasonsTableView.frame)
        print("table hidden?  ", reasonsTableView.isHidden)
        print("row count      ", reasonsTableView.numberOfRows(inSection: 0))
    }
    
    // MARK: - drop-down button
    private func setupChooseButton() {
        chooseButton.setTitle("Choose reason ▾", for: .normal)
        chooseButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        chooseButton.setTitleColor(.label, for: .normal)
        view.addSubview(chooseButton)
        
        chooseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chooseButton.leadingAnchor.constraint(equalTo: reasonLabel.trailingAnchor, constant: 12),
            chooseButton.centerYAnchor.constraint(equalTo: reasonLabel.centerYAnchor)
            
        ])
        
        
        let actions = list.map { reason in
            UIAction(title: reason) { [weak self] _ in
                self?.handleSelection(reason)
            }
        }
        chooseButton.menu = UIMenu(title: "", children: actions)
        chooseButton.showsMenuAsPrimaryAction = true
    }
    
    private func handleSelection(_ reason: String) {
        selectedReason = reason
        chooseButton.setTitle(reason, for: .normal)
        reasonsTableView.reloadData()
    }
 
    
    // MARK: - pick photo
    @IBAction func uploadPictureTapped(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
   

    
    // PHPicker callback
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.selectedImage = image as? UIImage
                let btn = self?.uploadPictureButton as UIButton?
                btn?.setTitle("Picture added ✓", for: .normal)
                self?.uploadPictureButton.setTitle("Picture added ✓", for: .normal)
            }
        }
    }
 
    
}

