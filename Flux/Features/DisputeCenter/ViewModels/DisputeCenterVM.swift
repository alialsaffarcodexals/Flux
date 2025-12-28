import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class DisputeCenterVM {
    
    // MARK: - Output
    private(set) var recipients: [String] = []   // will hold UID strings
    private(set) var reasons: [String] = ["Inappropriate content", "Spam", "Harassment", "Scam / fraud", "Other"]
    
    private var selectedRecipientIndex: Int?
    private var selectedReasonIndex: Int?
    private var selectedImage: UIImage?
    private var currentDescription: String = ""
    
    // MARK: - Callbacks
    var onRecipientsChanged: (() -> Void)?
    var onReasonsChanged: (() -> Void)?
    var onSendEnabledChanged: ((Bool) -> Void)?
    var onImagePicked: ((UIImage?) -> Void)?
    var onReportSubmitted: ((Error?) -> Void)?
    
    // MARK: - Dependencies (MVVM)
    private let reportRepo = ReportRepository.shared
    
    // MARK: - Public Methods
    func loadInitialData() {
        // Load Provider UIDs (people who can be reported)
        Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "Provider")
            .getDocuments { [weak self] snap, error in
                if let error = error {
                    self?.onReportSubmitted?(error)
                    return
                }
                self?.recipients = snap?.documents.compactMap { $0.documentID } ?? []
                print("🔥 Provider count = \(self?.recipients.count ?? 0)")
                self?.onRecipientsChanged?()
            }
    }
    
    func selectRecipient(at index: Int) {
        selectedRecipientIndex = index
        onRecipientsChanged?()
        validateSubmit()
    }
    
    func selectReason(at index: Int) {
        selectedReasonIndex = index
        onReasonsChanged?()
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
        // Validate inputs
        guard let rIdx = selectedRecipientIndex,
              let rsIdx = selectedReasonIndex,
              recipients.indices.contains(rIdx),
              reasons.indices.contains(rsIdx),
              let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines),
              !desc.isEmpty else {
            onReportSubmitted?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please complete all required fields"]))
            return
        }
        
        // Upload image if present, then create report
        if let image = selectedImage,
           let jpegData = image.jpegData(compressionQuality: 0.8) {
            
            let storageRef = Storage.storage().reference().child("reportEvidence/\(UUID().uuidString).jpg")
            
            storageRef.putData(jpegData, metadata: nil) { [weak self] _, error in
                if let error = error {
                    self?.onReportSubmitted?(error)
                    return
                }
                // Get download URL
                storageRef.downloadURL { url, error in
                    if let url = url {
                        self?.createReportInRepo(description: desc,
                                               reasonIdx: rsIdx,
                                               evidenceURL: url.absoluteString)
                    } else if let error = error {
                        self?.onReportSubmitted?(error)
                    }
                }
            }
        } else {
            // No image - create report immediately
            createReportInRepo(description: desc, reasonIdx: rsIdx, evidenceURL: nil)
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
    private func createReportInRepo(description: String, reasonIdx: Int, evidenceURL: String?) {
        guard let reporterID = Auth.auth().currentUser?.uid,
              let recipientIndex = selectedRecipientIndex,
              recipients.indices.contains(recipientIndex) else {
            onReportSubmitted?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user or recipient"]))
            return
        }
        
        let reportedID = recipients[recipientIndex]
        
        reportRepo.createReport(
            reporterId: reporterID,
            reportedUserId: reportedID,
            reason: reasons[reasonIdx],
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
        // Description is required, image is optional
        let hasValidRecipient = selectedRecipientIndex != nil
        let hasValidReason = selectedReasonIndex != nil
        let hasDescription = !currentDescription.isEmpty
        
        let canSend = hasValidRecipient && hasValidReason && hasDescription
        onSendEnabledChanged?(canSend)
    }
}
