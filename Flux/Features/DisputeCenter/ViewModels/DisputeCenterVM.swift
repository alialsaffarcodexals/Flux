import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class DisputeCenterVM {
    
    // MARK: - Output
    private(set) var recipients: [String] = []   // will hold UID strings
    private(set) var reasons: [String] = ["Inappropriate content", "Spam", "Harassment", "Scam / fraud", "Other"]
    
    // Selection state
    private(set) var selectedRecipientIndex: Int?
    private(set) var selectedReasonIndex: Int?
    private var selectedImage: UIImage?
    private var currentDescription: String = ""
    
    // MARK: - Callbacks
    var onRecipientsLoaded: (() -> Void)?  // Only called when recipients are first loaded
    var onSendEnabledChanged: ((Bool) -> Void)?
    var onImagePicked: ((UIImage?) -> Void)?
    var onReportSubmitted: ((Error?) -> Void)?
    
    // MARK: - Dependencies (MVVM)
    private let reportRepo = ReportRepository.shared
    
    // MARK: - Public Methods
    func setTargetRecipient(id: String, name: String) {
        self.recipients = [id]
        // Since we are locking to a specific user, we don't carry a separate 'names' array in this MVP logic
        // We will repurpose the recipients array or just store the single target state.
        // For MVP compatibility with existing VC logic which expects an index:
        self.selectedRecipientIndex = 0
        self.onRecipientsLoaded?()
        validateSubmit()
    }

    func loadInitialData() {
        // If we already have a selected recipient (passed from previous screen), don't fetch all.
        if selectedRecipientIndex != nil && !recipients.isEmpty {
            onRecipientsLoaded?()
            return
        }
        
        // Load Provider UIDs (people who can be reported)
        Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "Provider")
            .getDocuments { [weak self] snap, error in
                if let error = error {
                    print("Error loading providers: \(error.localizedDescription)")
                    self?.onReportSubmitted?(error)
                    return
                }
                self?.recipients = snap?.documents.compactMap { $0.documentID } ?? []
                print("Provider count = \(self?.recipients.count ?? 0)")
                self?.onRecipientsLoaded?()
            }
    }
    
    func selectRecipient(at index: Int) {
        guard recipients.indices.contains(index) else {
            print("Invalid recipient index: \(index)")
            return
        }
        selectedRecipientIndex = index
        print("Selected recipient at index \(index): \(recipients[index])")
        validateSubmit()
    }
    
    func selectReason(at index: Int) {
        guard reasons.indices.contains(index) else {
            print("Invalid reason index: \(index)")
            return
        }
        selectedReasonIndex = index
        print("Selected reason at index \(index): \(reasons[index])")
        validateSubmit()
    }
    
    func updateDescription(_ text: String?) {
        currentDescription = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        validateSubmit()
    }
    
    func userPickedImage(_ image: UIImage?) {
        selectedImage = image
        onImagePicked?(image)
        validateSubmit()
    }
    
    func submitReport(description: String?) {
        let reporterID = Auth.auth().currentUser?.uid ?? ""
        
        // Validate recipient selection
        guard let recipientIndex = selectedRecipientIndex,
              recipients.indices.contains(recipientIndex) else {
            onReportSubmitted?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please select a recipient"]))
            return
        }
        
        // Validate reason selection
        guard let reasonIndex = selectedReasonIndex,
              reasons.indices.contains(reasonIndex) else {
            onReportSubmitted?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please select a reason"]))
            return
        }
        
        // Validate description
        guard let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines),
              !desc.isEmpty else {
            onReportSubmitted?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter a description"]))
            return
        }
        
        let reportedID = recipients[recipientIndex]
        let reason = reasons[reasonIndex]
        
        // Upload image if present, then create report (image is optional)
        if let image = selectedImage,
           let jpegData = image.jpegData(compressionQuality: 0.8) {
            
            let storageRef = Storage.storage().reference().child("reportEvidence/\(UUID().uuidString).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(jpegData, metadata: metadata) { [weak self] metadata, error in
                if let error = error {
                    self?.onReportSubmitted?(error)
                    return
                }
                
                // Fetch URL after successful upload
                storageRef.downloadURL { url, error in
                    if let url = url {
                        self?.createReport(
                            reporterID: reporterID,
                            reportedID: reportedID,
                            reason: reason,
                            description: desc,
                            evidenceURL: url.absoluteString
                        )
                    } else {
                        // If downloadURL fails (e.g., due to write-only permissions),
                        // we still submit the report using the storage path so admins can find it.
                        print("Could not fetch download URL (likely permission issue): \(error?.localizedDescription ?? "Unknown")")
                        self?.createReport(
                            reporterID: reporterID,
                            reportedID: reportedID,
                            reason: reason,
                            description: desc,
                            evidenceURL: "gs://flux/\(storageRef.fullPath)"
                        )
                    }
                }
            }
        } else {
            // No image - create report immediately (image is optional)
            createReport(
                reporterID: reporterID,
                reportedID: reportedID,
                reason: reason,
                description: desc,
                evidenceURL: nil
            )
        }
    }
    
    // MARK: - Helper Methods
    func isRecipientSelected(at index: Int) -> Bool {
        return selectedRecipientIndex == index
    }
    
    func isReasonSelected(at index: Int) -> Bool {
        return selectedReasonIndex == index
    }
    
    // MARK: - Private Methods
    private func createReport(reporterID: String, reportedID: String, reason: String, description: String, evidenceURL: String?) {
        reportRepo.createReport(
            reporterId: reporterID,
            reportedUserId: reportedID,
            reason: reason,
            description: description,
            evidenceImageURL: evidenceURL,
            status: "Open"
        ) { [weak self] result in
            switch result {
            case .success:
                self?.onReportSubmitted?(nil)
            case .failure(let error):
                self?.onReportSubmitted?(error)
            }
        }
    }
    
    private func validateSubmit() {
        let hasValidRecipient = selectedRecipientIndex != nil
        let hasValidReason = selectedReasonIndex != nil
        let hasDescription = !currentDescription.isEmpty
        
        let canSend = hasValidRecipient && hasValidReason && hasDescription
        onSendEnabledChanged?(canSend)
    }
}
