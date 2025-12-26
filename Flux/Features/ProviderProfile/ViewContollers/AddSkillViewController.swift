/*
 File: AddSkillViewController.swift
 Purpose: Swift declarations for the Flux app.
 Location: Features/ProviderProfile/ViewContollers/AddSkillViewController.swift
*/
















import UIKit
import FirebaseAuth

final class AddSkillViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField?
    @IBOutlet weak var levelSegmentedControl: UISegmentedControl?
    @IBOutlet weak var descriptionTextView: UITextView?
    @IBOutlet weak var uploadProofButton: UIButton?
    @IBOutlet weak var uploadProofStatusLabel: UILabel?

    private let viewModel = AddSkillViewModel()
    private var selectedProofImage: UIImage?
    private var uploadedProofURL: String?
    private var uploadedProofName: String?
    private var isUploadingProof = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }

    private func setupBindings() {
        viewModel.onSaveSuccess = { [weak self] in
            self?.showSuccessAlert()
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }
    }

    @IBAction private func uploadProofTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction private func saveTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "Confirm",
            message: "Do you want to save and submit this skill?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.submitSkill()
        })
        present(alert, animated: true)
    }

    private func submitSkill() {
        guard let providerId = Auth.auth().currentUser?.uid else { return }

        let name = nameTextField?.text ?? ""
        let description = descriptionTextView?.text

        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "Please enter a skill name.")
            return
        }

        guard let level = selectedSkillLevel() else {
            showAlert(message: "Please select a skill level.")
            return
        }

        if isUploadingProof {
            showAlert(message: "Please wait for the proof image to finish uploading.")
            return
        }

        guard let proofURL = uploadedProofURL, !proofURL.isEmpty else {
            showAlert(message: "Please upload a proof image.")
            return
        }

        viewModel.saveSkill(
            providerId: providerId,
            name: name,
            level: level,
            description: description,
            proofImageURL: proofURL
        )
    }

    private func selectedSkillLevel() -> SkillLevel? {
        guard let segmentedControl = levelSegmentedControl else {
            return nil
        }

        let index = segmentedControl.selectedSegmentIndex
        guard index != UISegmentedControl.noSegment else {
            return nil
        }

        let title = segmentedControl.titleForSegment(at: index) ?? ""
        return SkillLevel(rawValue: title)
    }

    private func showAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func showSuccessAlert() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "Success",
                message: "Skill was successfully saved and submitted",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            self?.present(alert, animated: true)
        }
    }

    private func updateProofStatusLabel(text: String) {
        DispatchQueue.main.async { [weak self] in
            if let label = self?.uploadProofStatusLabel {
                label.text = text
                return
            }

            if let label = self?.findProofStatusLabel(in: self?.view) {
                label.text = text
                self?.uploadProofStatusLabel = label
            }
        }
    }

    private func findProofStatusLabel(in rootView: UIView?) -> UILabel? {
        guard let rootView = rootView else { return nil }
        for subview in rootView.subviews {
            if let label = subview as? UILabel,
               label.text?.localizedCaseInsensitiveContains("proof") == true {
                return label
            }
            if let match = findProofStatusLabel(in: subview) {
                return match
            }
        }
        return nil
    }
}

extension AddSkillViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        if let image = info[.originalImage] as? UIImage {
            selectedProofImage = image
            let originalName = (info[.imageURL] as? URL)?.lastPathComponent
            uploadProof(image: image, originalName: originalName)
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func uploadProof(image: UIImage, originalName: String?) {
        guard !isUploadingProof else { return }
        isUploadingProof = true
        uploadedProofURL = nil
        uploadedProofName = nil
        viewModel.uploadProofImage(image) { [weak self] result in
            guard let self = self else { return }
            self.isUploadingProof = false
            switch result {
            case .success(let url):
                self.uploadedProofURL = url
                let proofName = self.resolveProofName(originalName: originalName, urlString: url)
                self.uploadedProofName = proofName
                self.updateProofStatusLabel(
                    text: "\(proofName) has been uploaded and will be reviewed by the admin"
                )
            case .failure(let error):
                self.showAlert(message: error.localizedDescription)
            }
        }
    }

    private func resolveProofName(originalName: String?, urlString: String) -> String {
        if let originalName = originalName, !originalName.isEmpty {
            return originalName
        }

        if let url = URL(string: urlString) {
            return url.lastPathComponent
        }

        return "Proof"
    }
}
