/*
 File: DisputeCenterVC.swift
 Purpose: Handles the dispute center report form.
 Location: Features/DisputeCenter/ViewControllers/DisputeCenterVC.swift
*/

import UIKit
import PhotosUI

class DisputeCenterVC: UIViewController,
                       UIImagePickerControllerDelegate,
                       UINavigationControllerDelegate {

    // MARK: - Outlets
    @IBOutlet weak var recipientTableView: UITableView!
    @IBOutlet weak var reasonsTableView: UITableView!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var uploadPictureButton: UIButton!
    @IBOutlet weak var sendReportButton: UIButton!
   
    // MARK: - ViewModel
    private let viewModel = DisputeCenterVM()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableViews()
        setupInitialState()
        bindViewModel()
        viewModel.loadInitialData()
    }

    private func setupTableViews() {
        recipientTableView.dataSource = self
        recipientTableView.delegate = self
        reasonsTableView.dataSource = self
        reasonsTableView.delegate = self

        recipientTableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecipientCell")
        reasonsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReasonCell")
    }

    private func setupInitialState() {
        sendReportButton.isEnabled = false
        uploadPictureButton.setTitle("Upload Picture", for: .normal)
    }
    
    private func bindViewModel() {
        // Bind to ViewModel callbacks
        viewModel.onRecipientsChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.recipientTableView.reloadData()
            }
        }
        
        viewModel.onReasonsChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.reasonsTableView.reloadData()
            }
        }
        
        viewModel.onSendEnabledChanged = { [weak self] isEnabled in
            DispatchQueue.main.async {
                self?.sendReportButton.isEnabled = isEnabled
            }
        }
        
        viewModel.onImagePicked = { [weak self] image in
            DispatchQueue.main.async {
                let title = image != nil ? "Picture Selected ✓" : "Upload Picture"
                self?.uploadPictureButton.setTitle(title, for: .normal)
            }
        }
        
        viewModel.onReportSubmitted = { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    self?.showAlert(title: "Success", message: "Report submitted successfully") {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    // MARK: - Actions
    @IBAction func uploadPictureTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func sendReportTapped(_ sender: UIButton) {
        viewModel.submitReport(description: descriptionTextField.text)
    }

    @IBAction func descriptionChanged(_ sender: UITextField) {
        viewModel.updateDescription(sender.text)
    }
}

extension DisputeCenterVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === recipientTableView {
            return viewModel.recipients.count
        }
        return viewModel.reasons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === recipientTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecipientCell", for: indexPath)
            cell.textLabel?.text = viewModel.recipients[indexPath.row]
            cell.accessoryType = viewModel.isRecipientSelected(at: indexPath.row) ? .checkmark : .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "ReasonCell", for: indexPath)
        cell.textLabel?.text = viewModel.reasons[indexPath.row]
        cell.accessoryType = viewModel.isReasonSelected(at: indexPath.row) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView === recipientTableView {
            viewModel.selectRecipient(at: indexPath.row)
        } else {
            viewModel.selectReason(at: indexPath.row)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            viewModel.userPickedImage(image)
        }
    }
}
