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
   

    // MARK: - Data
    private let recipients: [String] = []
    private let reasons: [String] = []
    private var selectedRecipientIndex: IndexPath?
    private var selectedReasonIndex: IndexPath?

    
    private let viewModel = DisputeCenterVM()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableViews()
        setupInitialState()
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
    }

    private func updateSendReportAvailability() {
        let hasDescription = !(descriptionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        sendReportButton.isEnabled = selectedRecipientIndex != nil && selectedReasonIndex != nil && hasDescription
    }

    // MARK: - Actions
    @IBAction func uploadPictureTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
           picker.sourceType = .photoLibrary
           picker.delegate = self
           present(picker, animated: true)
    }

    @IBAction func sendReportTapped(_ sender: UIButton) {
        viewModel.submitReport(description: descriptionTextField.text,
                               recipientIndex: recipientTableView.indexPathForSelectedRow,
                               reasonIndex:   reasonsTableView.indexPathForSelectedRow)
    }

    @IBAction func descriptionChanged(_ sender: UITextField) {
        updateSendReportAvailability()
    }
}

extension DisputeCenterVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === recipientTableView {
            return recipients.count
        }
        return reasons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === recipientTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecipientCell", for: indexPath)
            cell.textLabel?.text = recipients[indexPath.row]
            cell.accessoryType = (indexPath == selectedRecipientIndex) ? .checkmark : .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "ReasonCell", for: indexPath)
        cell.textLabel?.text = reasons[indexPath.row]
        cell.accessoryType = (indexPath == selectedReasonIndex) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === recipientTableView {
            selectedRecipientIndex = indexPath
        } else {
            selectedReasonIndex = indexPath
        }
        tableView.reloadData()
        updateSendReportAvailability()
    }
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            // TODO: pass to ViewModel
            // viewModel.userPickedImage(image)
        }
    }
}
