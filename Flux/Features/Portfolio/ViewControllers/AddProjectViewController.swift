//
//  AddProjectViewController.swift
//  Flux
//
//  Created by Guest User on 30/12/2025.
//

import UIKit
import Cloudinary
import FirebaseFirestore
import FirebaseAuth

class AddProjectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var uploadView: UIView!
    
    var selectedImage: UIImage?
    let placeholderText = "Describe your service and experience"
    var editingProject: PortfolioProject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSelectPhoto))
        uploadView.addGestureRecognizer(tap)
        uploadView.isUserInteractionEnabled = true
        
        descriptionTextView.delegate = self
        descriptionTextView.text = placeholderText
        descriptionTextView.textColor = .lightGray
        
        setupDesign()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addDashedBorder() // Draw dashed border after layout is calculated
    }
    
    // MARK: - Navigation Action
    @IBAction func saveBarButtonTapped(_ sender: Any) {
        guard let name = projectNameTextField.text, !name.isEmpty,
              let desc = descriptionTextView.text, desc != placeholderText,
              let image = selectedImage,
              let currentUserId = Auth.auth().currentUser?.uid else {
            showAlert(message: "Please fill all fields and select a photo.")
            return
        }
// error for faild uploding
        uploadToCloudinary(image: image) { imageUrl in
            guard let url = imageUrl else {
                self.showAlert(message: "Image upload failed. Check Cloudinary settings.")
                return
            }

            let imageUrls = [url]

            
            if let originalId = self.editingProject?.id {
                let updatedProject = PortfolioProject(
                    id: originalId,
                    providerId: currentUserId,
                    title: name,
                    description: desc,
                    imageURLs: imageUrls,
                    timestamp: self.datePicker.date
                )

                PortfolioRepository.shared.updatePortfolioProject(updatedProject) { result in
                    self.handleRepositoryResult(result)
                }
            } else {
                let newProject = PortfolioProject(
                    id: nil,
                    providerId: currentUserId,
                    title: name,
                    description: desc,
                    imageURLs: imageUrls,
                    timestamp: self.datePicker.date
                )

                PortfolioRepository.shared.createPortfolioProject(newProject) { result in
                    switch result {
                    case .success: self.performSegue(withIdentifier: "toSuccessScreen", sender: self)
                    case .failure(let error): self.showAlert(message: error.localizedDescription)
                    }
                }
            }
        }
    }

    func handleRepositoryResult(_ result: Result<Void, Error>) {
        switch result {
        case .success:
            self.performSegue(withIdentifier: "toSuccessScreen", sender: self)
        case .failure(let error):
            self.showAlert(message: error.localizedDescription)
        }
    }

    func uploadToCloudinary(image: UIImage, completion: @escaping (String?) -> Void) {
        let myCloudName = "dya8qyprj"
        let myPreset = "flux_preset"
        let config = CLDConfiguration(cloudName: myCloudName, apiKey: "216725321758734")
        let cloudinary = CLDCloudinary(configuration: config)
        
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        cloudinary.createUploader().upload(data: data, uploadPreset: myPreset, completionHandler: { result, error in
            if let error = error {
                print("DEBUG CLOUDINARY ERROR: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(result?.secureUrl)
            }
        })
    }

    // MARK: - Styling
    func setupDesign() {
        descriptionTextView.layer.cornerRadius = 12
        descriptionTextView.backgroundColor = UIColor.systemGray6
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        descriptionTextView.clipsToBounds = true
        
        uploadView.backgroundColor = UIColor.systemGray6
        uploadView.layer.cornerRadius = 12
        uploadView.clipsToBounds = true
        
        projectNameTextField.textColor = .black
        projectNameTextField.font = .systemFont(ofSize: 16, weight: .regular)
    }
    
    func addDashedBorder() {
        uploadView.layer.sublayers?.filter { $0 is CAShapeLayer }.forEach { $0.removeFromSuperlayer() }
        let shapeLayer = CAShapeLayer()
        let shapeRect = CGRect(x: 0, y: 0, width: uploadView.frame.width, height: uploadView.frame.height)
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: uploadView.frame.width/2, y: uploadView.frame.height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.systemGray3.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineDashPattern = [6, 3]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 12).cgPath
        uploadView.layer.addSublayer(shapeLayer)
    }

    // MARK: - TextView Placeholder Logic
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderText
            textView.textColor = .lightGray
        }
    }
    
    // MARK: - Image Picker
    @objc func handleSelectPhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            self.selectedImage = image
            uploadView.subviews.forEach { if $0 is UIImageView { $0.removeFromSuperview() } }
            
            let preview = UIImageView(image: image)
            preview.frame = uploadView.bounds
            preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            preview.contentMode = .scaleAspectFill
            preview.clipsToBounds = true
            preview.layer.cornerRadius = 12
            uploadView.addSubview(preview)
            
            uploadView.layer.sublayers?.forEach { if $0 is CAShapeLayer { $0.zPosition = 1 } }
        }
        dismiss(animated: true)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Flux", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
