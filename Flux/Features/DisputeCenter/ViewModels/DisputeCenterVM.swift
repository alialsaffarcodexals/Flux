//
//  DisputeCenterVM.swift
//  Flux
//
//  Created by Mohammed on 27/12/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

final class DisputeCenterVM: ObservableObject {
    
    // MARK: - Output
    private(set) var recipients: [String] = ["User A", "User B", "Admin"]   // TODO: fetch real list
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
    
    // MARK: - Intents
    func loadInitialData() {
        onRecipientsChanged?()   // triggers reload with dummy list
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
        
        // 1.  upload image (if any)  →  2.  save report
        if let image = selectedImage,
           let jpegData = image.jpegData(compressionQuality: 0.8) {
            
            let storageRef = Storage.storage().reference()
                .child("reportEvidence/\(UUID().uuidString).jpg")
            
            storageRef.putData(jpegData, metadata: nil) { [weak self] _, error in
                if let error = error {
                    self?.onReportSubmitted?(error)
                    return
                }
                // get download URL
                storageRef.downloadURL { url, error in
                    let imageURL = url?.absoluteString
                    self?.saveReportToFirestore(description: desc,
                                              reasonIdx: rsIdx,
                                              evidenceURL: imageURL,
                                              reporterID: "user_101",
                                              reportedID: "user_202")
                }
            }
        } else {
            // no image – save immediately
            saveReportToFirestore(description: desc,
                                reasonIdx: rsIdx,
                                evidenceURL: nil,
                                reporterID: "user_101",
                                reportedID: "user_202")
        }
    }
    
    // MARK: - Private
    private func saveReportToFirestore(description: String,
                                     reasonIdx: Int,
                                     evidenceURL: String?,
                                     reporterID: String,
                                     reportedID: String) {
        let report = Report(
            reporterId: reporterID,
            reportedUserId: reportedID,
            reason: reasons[reasonIdx],
            description: description,
            evidenceImageURL: evidenceURL,
            status: "Open",
            timestamp: Date()
        )
        
        let reportRef = Firestore.firestore()
                                 .collection("reports")
                                 .document()   // auto-ID
        
        do {
            try reportRef.setData(from: report) { [weak self] error in
                self?.onReportSubmitted?(error)
            }
        } catch {
            onReportSubmitted?(error)
        }
    }
    
    private func validateSubmit() {
        let canSend = (selectedRecipientIndex != nil) && (selectedReasonIndex != nil) && (selectedImage != nil)
        onSendEnabledChanged?(canSend)
    }
}
