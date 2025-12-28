import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class DisputeCenterVM: ObservableObject {
    
    // MARK: - Output
    private(set) var recipients: [String] = []   // will hold UID strings
    private(set) var reasons: [String]  = ["Inappropriate content", "Spam", "Harassment", "Scam / fraud", "Other"]
    
    private(set) var selectedRecipientIndex: IndexPath?
    private(set) var selectedReasonIndex: IndexPath?
    private(set) var selectedImage: UIImage?
    
    // MARK: - Callbacks
    var onRecipientsChanged: (() -> Void)?
    var onReasonsChanged: (() -> Void)?
    var onSendEnabledChanged: ((Bool) -> Void)?
    var onImagePicked: ((UIImage?) -> Void)?
    var onReportSubmitted: ((Error?) -> Void)?
    
    // MARK: - Dependencies (MVVM)
    private let reportRepo = ReportRepository.shared
    private let storageRepo = StorageManager.shared   // uploads images
    
    // MARK: - Intents
    func loadInitialData() {
        // fetch only **Provider** role users (people who can be reported)
        Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "Provider")
            .getDocuments { [weak self] snap, error in
                if let error = error {
                    self?.onReportSubmitted?(error)   // surface fetch error
                    return
                }
                // map every doc → its **document ID** (the UID)
                self?.recipients = snap?.documents.compactMap { $0.documentID } ?? []
                self?.onRecipientsChanged?()
            }
    }
    
    func selectRecipient(at indexPath: IndexPath) {
        selectedRecipientIndex = indexPath
        onRecipientsChanged?()
        validateSubmit()
    }
    
    func selectReason(at indexPath: IndexPath) {
        selectedReasonIndex = indexPath
        onReasonsChanged?()
        validateSubmit()
    }
    
    func updateDescription(_ text: String?) {
        validateSubmit()
    }
    
    func userPickedImage(_ image: UIImage?) {
        selectedImage = image
        onImagePicked?(image)
        validateSubmit()
    }
    
    func submitReport(description: String?, recipientIndex: IndexPath?, reasonIndex: IndexPath?) {
        // basic validation
        guard let rIdx = recipientIndex?.row,
              let rsIdx = reasonIndex?.row,
              recipients.indices.contains(rIdx),
              reasons.indices.contains(rsIdx),
              let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines),
              !desc.isEmpty else {
            onReportSubmitted?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please complete all fields"]))
            return
        }
        
        // 1.  upload image (if any)  →  2.  create report via Repo
        if let image = selectedImage,
           let jpegData = image.jpegData(compressionQuality: 0.8) {
            
            let storageRef = Storage.storage().reference().child("reportEvidence/\(UUID().uuidString).jpg")
            
            storageRef.putData(jpegData, metadata: nil) { [weak self] _, error in
                if let error = error {
                    self?.onReportSubmitted?(error)
                    return
                }
                // get download URL
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
            // no image – create report immediately
            createReportInRepo(description: desc, reasonIdx: rsIdx, evidenceURL: nil)
        }
    }
    // MARK: - Private
    private func createReportInRepo(description: String, reasonIdx: Int, evidenceURL: String?) {
        // fetch real reporter & reported IDs from Firestore
        let reporterID   = Auth.auth().currentUser?.uid ?? "anonymous"   // logged-in user
        let reportedID   = recipients[selectedRecipientIndex?.row ?? 0]  // recipient you picked
        
        ReportRepository.shared.createReport(
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
        let canSend = (selectedRecipientIndex != nil) && (selectedReasonIndex != nil) && (selectedImage != nil)
        onSendEnabledChanged?(canSend)
    }
}
