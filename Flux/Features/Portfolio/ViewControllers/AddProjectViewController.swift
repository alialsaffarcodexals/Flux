//
//  AddProjectViewController.swift
//  Flux
//
//  Created by Guest User on 30/12/2025.
//

import UIKit
import Cloudinary
import FirebaseFirestore

class AddProjectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var uploadView: UIView!
    var selectedImage: UIImage?
    let db = Firestore.firestore()
    let placeholderText = "Describe your service and experience"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tap gesture for Upload View
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSelectPhoto))
        uploadView.addGestureRecognizer(tap)
        uploadView.isUserInteractionEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    addDashedBorder() // Draw dashed border after layout is calculated
        }
    
    // MARK: - Navigation Action
        @IBAction func saveBarButtonTapped(_ sender: UIBarButtonItem) {
            validateAndUpload()
        }
        
        // MARK: - Validation & Upload Logic
        func validateAndUpload() {
            guard let name = projectNameTextField.text, !name.isEmpty,
                  let desc = descriptionTextView.text, desc != placeholderText, !desc.isEmpty,
                  let image = selectedImage else {
                showAlert(message: "Please fill all fields and upload a project image.")
                return
            }
            
            // Step 1: Upload to Cloudinary
            uploadImageToCloudinary(image: image) { imageUrl in
                guard let url = imageUrl else {
                    self.showAlert(message: "Image upload failed.")
                    return
                }
                
                // Step 2: Save to Firebase
                self.saveToFirebase(name: name, date: self.datePicker.date, description: desc, imageUrl: url)
            }
        }
        
        func uploadImageToCloudinary(image: UIImage, completion: @escaping (String?) -> Void) {
            let config = CLDConfiguration(cloudName: "your_cloud_name", apiKey: "your_api_key")
            let cloudinary = CLDCloudinary(configuration: config)
            
            guard let data = image.jpegData(compressionQuality: 0.7) else { return }
            
            cloudinary.createUploader().upload(data: data, uploadPreset: "your_preset", completionHandler: { result, error in
                if let error = error {
                    print("Cloudinary Error: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(result?.secureUrl)
                }
            })
        }
        
        func saveToFirebase(name: String, date: Date, description: String, imageUrl: String) {
            let data: [String: Any] = [
                "projectName": name,
                "date": date,
                "description": description,
                "imageUrl": imageUrl,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            db.collection("Projects").addDocument(data: data) { error in
                if let error = error {
                    self.showAlert(message: "Error saving: \(error.localizedDescription)")
                } else {
                    // SUCCESS! Instead of just going back, we trigger the Segue
                    self.performSegue(withIdentifier: "toSuccessScreen", sender: self)
                }
            }
        }
        
        // MARK: - Figma Styling
        func setupDesign() {
            descriptionTextView.text = placeholderText
            descriptionTextView.textColor = .lightGray
            descriptionTextView.layer.cornerRadius = 12
            descriptionTextView.backgroundColor = UIColor.systemGray6
            descriptionTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            
            uploadView.backgroundColor = UIColor.systemGray6
            uploadView.layer.cornerRadius = 12
            uploadView.clipsToBounds = true // Fixes date picker radius issues
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
                let preview = UIImageView(image: image)
                preview.frame = uploadView.bounds
                preview.contentMode = .scaleAspectFill
                uploadView.addSubview(preview)
            }
            dismiss(animated: true)
        }
        
        func showAlert(message: String) {
            let alert = UIAlertController(title: "Flux", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
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



