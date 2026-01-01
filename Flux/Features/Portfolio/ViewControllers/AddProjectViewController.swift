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
    let db = Firestore.firestore()
    let placeholderText = "Describe your service and experience"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tap gesture for Upload View
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSelectPhoto))
        uploadView.addGestureRecognizer(tap)
        uploadView.isUserInteractionEnabled = true
        descriptionTextView.delegate = self
        descriptionTextView.text = "Describe your service and experience"
        descriptionTextView.textColor = .lightGray
        setupDesign()
    }
    func uploadToCloudinary(image: UIImage, completion: @escaping (String?) -> Void) {
        // 1. DOUBLE CHECK THESE TWO STRINGS
        let myCloudName = "dya8qyprj"
        let myPreset = "flux_preset"
        
        let config = CLDConfiguration(cloudName: myCloudName, apiKey: "216725321758734")
        let cloudinary = CLDCloudinary(configuration: config)
        
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            completion(nil) // Add this so the app knows it stopped
            return
        }
        cloudinary.createUploader().upload(data: data, uploadPreset: myPreset, completionHandler: { result, error in
            if let error = error {
                // LOOK AT YOUR XCODE CONSOLE (Bottom of screen) FOR THIS MESSAGE:
                print("DEBUG CLOUDINARY ERROR: \(error.localizedDescription)")
                print("ERROR DETAILS: \(error)")
                
                completion(nil)
            } else {
                completion(result?.secureUrl)
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    addDashedBorder() // Draw dashed border after layout is calculated
        }
    
    // MARK: - Navigation Action
        @IBAction func saveBarButtonTapped(_ sender: Any) {
            // 1. Validation
            guard let name = projectNameTextField.text, !name.isEmpty,
                  let desc = descriptionTextView.text, desc != "Describe your service and experience",
                  let image = selectedImage,
                  let currentUserId = Auth.auth().currentUser?.uid else {
                showAlert(message: "Please fill all fields and select a photo.")
                return
            }

            // 2. Upload to Cloudinary First
            // (Make sure to use your REAL Cloudinary Name and Preset here)
            uploadToCloudinary(image: image) { imageUrl in
                guard let url = imageUrl else {
                    self.showAlert(message: "Image upload failed. Check Cloudinary settings.")
                    return
                }

                // 3. Create the Model object
                let newProject = PortfolioProject(
                    id: nil, // The Repository will generate this
                    providerId: currentUserId,
                    title: name,
                    description: desc,
                    imageURLs: [url], // Cloudinary URL goes here
                    timestamp: self.datePicker.date
                )

                // 4. Use YOUR Repository to save to Firebase
                PortfolioRepository.shared.createPortfolioProject(newProject) { result in
                    switch result {
                    case .success(let createdProject):
                        print("Project saved with ID: \(createdProject.id ?? "unknown")")
                        // Success! Transition to the success screen
                        self.performSegue(withIdentifier: "toSuccessScreen", sender: self)
                        
                    case .failure(let error):
                        self.showAlert(message: "Firebase Error: \(error.localizedDescription)")
                    }
                }
            }
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
        
        // MARK: - Styling
        func setupDesign() {
            descriptionTextView.text = placeholderText
            descriptionTextView.textColor = .lightGray
            descriptionTextView.layer.cornerRadius = 12
            descriptionTextView.backgroundColor = UIColor.systemGray6
            descriptionTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            descriptionTextView.clipsToBounds = true
            
            uploadView.backgroundColor = UIColor.systemGray6
            uploadView.layer.cornerRadius = 12
            uploadView.clipsToBounds = true
            
            projectNameTextField.textColor = .black         // Makes text dark
            projectNameTextField.font = .systemFont(ofSize: 16, weight: .regular) // Adjust size as needed
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
            
            // Remove any old previews before adding a new one
            uploadView.subviews.forEach { if $0 is UIImageView { $0.removeFromSuperview() } }
            
            let preview = UIImageView(image: image)
            
            // FIX: Ensure the preview is exactly the same size as the box
            preview.frame = uploadView.bounds
            preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // FIX: These 2 lines stop the image from spilling out
            preview.contentMode = .scaleAspectFill
            preview.clipsToBounds = true
            
            // FIX: Give the image the same radius as the box
            preview.layer.cornerRadius = 12
            
            uploadView.addSubview(preview)
            
            // Bring the dashed border to the front so it stays visible
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
   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */



