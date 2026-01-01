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
    @IBOutlet weak var saveButton: UIButton!
    
    var selectedImage: UIImage? // Fixes: cannot find 'selectedImage'
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSelectPhoto))
        uploadView.addGestureRecognizer(tap)
        uploadView.isUserInteractionEnabled = true
    }
    
    @objc func handleSelectPhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    // Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            self.selectedImage = image
            // Optional: show a small preview inside your uploadView
        }
        dismiss(animated: true)
    }
    @IBAction func saveProjectPressed(_ sender: UIButton) {
        guard let name = projectNameTextField.text, !name.isEmpty,
              let desc = descriptionTextView.text, !desc.isEmpty,
              let image = selectedImage else {
            print("Please fill all fields and select an image")
            return
        }
        
        // Disable button to prevent double-clicks
        saveButton.isEnabled = false
        
        func uploadToCloudinary(image: UIImage, completion: @escaping (String?) -> Void) {
            let config = CLDConfiguration(cloudName: "your_cloud_name", apiKey: "your_api_key")
            let cloudinary = CLDCloudinary(configuration: config)
            
            guard let data = image.jpegData(compressionQuality: 0.7) else { return }
            
            // Fixed: Added 'completionHandler:' label to suppress warning
            cloudinary.createUploader().upload(data: data, uploadPreset: "your_unsigned_preset", completionHandler: { result, error in
                if let error = error {
                    print("Cloudinary Error: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(result?.secureUrl)
                }
            })
        }
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



