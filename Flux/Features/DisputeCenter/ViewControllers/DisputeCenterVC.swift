/*
 File: DisputeCenterVC.swift
 Purpose: Handles the dispute center report form.
 Location: Features/DisputeCenter/ViewControllers/DisputeCenterVC.swift
*/

import UIKit
import PhotosUI

class DisputeCenterVC: UIViewController,
                       UIImagePickerControllerDelegate,
                       UINavigationControllerDelegate,
                       UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var recipientTableView: UITableView!
    @IBOutlet weak var reasonsTableView: UITableView!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var uploadPictureButton: UIButton!
    @IBOutlet weak var sendReportButton: UIButton!
   
    // MARK: - ViewModel
    private let viewModel = DisputeCenterVM()
    
    // MARK: - Dropdown State
    private var isRecipientExpanded = false
    private var isReasonExpanded = false

    // MARK: - Properties
    var providerToReport: (id: String, name: String)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableViews()
        setupTextField()
        setupInitialState()
        bindViewModel()
        
        if let provider = providerToReport {
            viewModel.setTargetRecipient(id: provider.id, name: provider.name)
        }
        viewModel.loadInitialData()
    }

    private func setupTableViews() {
        recipientTableView.dataSource = self
        recipientTableView.delegate = self
        reasonsTableView.dataSource = self
        reasonsTableView.delegate = self

        recipientTableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecipientCell")
        reasonsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReasonCell")
        
        // Style table views
        recipientTableView.layer.cornerRadius = 8
        recipientTableView.layer.borderWidth = 1
        recipientTableView.layer.borderColor = UIColor.systemGray4.cgColor
        recipientTableView.clipsToBounds = true
        
        reasonsTableView.layer.cornerRadius = 8
        reasonsTableView.layer.borderWidth = 1
        reasonsTableView.layer.borderColor = UIColor.systemGray4.cgColor
        reasonsTableView.clipsToBounds = true
    }
    
    private func setupTextField() {
        descriptionTextField.delegate = self
        descriptionTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    private func setupInitialState() {
        sendReportButton.isEnabled = false
        uploadPictureButton.setTitle("Upload Picture", for: .normal)
    }
    
    private func bindViewModel() {
        viewModel.onRecipientsLoaded = { [weak self] in
            DispatchQueue.main.async {
                self?.recipientTableView.reloadData()
            }
        }
        
        viewModel.onSendEnabledChanged = { [weak self] isEnabled in
            DispatchQueue.main.async {
                self?.sendReportButton.isEnabled = isEnabled
                self?.sendReportButton.alpha = isEnabled ? 1.0 : 0.5
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
                    self?.showAlert(title: "Success", message: "Your report has been submitted successfully to the admin.") {
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
    
    // MARK: - Header Creation
    private func createDropdownHeader(title: String, isExpanded: Bool, action: Selector, isLocked: Bool = false) -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)
        label.textColor = isLocked ? .label : .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        // Only show chevron and enable tap if NOT locked
        if !isLocked {
            let chevron = UIImageView(image: UIImage(systemName: isExpanded ? "chevron.up" : "chevron.down"))
            chevron.tintColor = .systemGray
            chevron.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(chevron)
            
            NSLayoutConstraint.activate([
                chevron.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                chevron.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                chevron.widthAnchor.constraint(equalToConstant: 16),
                chevron.heightAnchor.constraint(equalToConstant: 10)
            ])
            
            let tapGesture = UITapGestureRecognizer(target: self, action: action)
            headerView.addGestureRecognizer(tapGesture)
        }
        
        return headerView
    }
    
    @objc private func recipientHeaderTapped() {
        // If locked to a provider, do nothing (gesture logic handled in creation)
        if providerToReport != nil { return }
        
        isRecipientExpanded.toggle()
        recipientTableView.reloadData()
        
        // Collapse the other dropdown
        if isRecipientExpanded && isReasonExpanded {
            isReasonExpanded = false
            reasonsTableView.reloadData()
        }
    }
    
    @objc private func reasonHeaderTapped() {
        isReasonExpanded.toggle()
        reasonsTableView.reloadData()
        
        // Collapse the other dropdown
        if isReasonExpanded && isRecipientExpanded {
            isRecipientExpanded = false
            recipientTableView.reloadData()
        }
    }
    
    private func getRecipientHeaderTitle() -> String {
        if let provider = providerToReport {
            return "Recipient: \(provider.name)"
        }
        
        if let index = viewModel.selectedRecipientIndex,
           viewModel.recipients.indices.contains(index) {
            // Logic change: viewModel.recipients only stores IDs now if locked.
            // If unlocked, it stores IDs, but we don't have Names map here for MVP simplicity.
            // But if locked, we return the locked name.
            // For the MVP, if not locked, we just show the ID or "Provider Selected"
            return "Provider Selected"
        }
        return "Select Recipient"
    }
    
    private func getReasonHeaderTitle() -> String {
        if let index = viewModel.selectedReasonIndex,
           viewModel.reasons.indices.contains(index) {
            return viewModel.reasons[index]
        }
        return "Select Reason"
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
    
    // MARK: - UITextFieldDelegate
    @objc private func textFieldDidChange(_ textField: UITextField) {
        viewModel.updateDescription(textField.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension DisputeCenterVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === recipientTableView {
            // If locked, we don't show rows
            if providerToReport != nil { return 0 }
            return isRecipientExpanded ? viewModel.recipients.count : 0
        }
        return isReasonExpanded ? viewModel.reasons.count : 0
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView === recipientTableView {
            return createDropdownHeader(
                title: getRecipientHeaderTitle(),
                isExpanded: isRecipientExpanded,
                action: #selector(recipientHeaderTapped),
                isLocked: providerToReport != nil
            )
        }
        return createDropdownHeader(
            title: getReasonHeaderTitle(),
            isExpanded: isReasonExpanded,
            action: #selector(reasonHeaderTapped)
        )
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView === recipientTableView {
            viewModel.selectRecipient(at: indexPath.row)
            isRecipientExpanded = false
            recipientTableView.reloadData()
        } else {
            viewModel.selectReason(at: indexPath.row)
            isReasonExpanded = false
            reasonsTableView.reloadData()
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
