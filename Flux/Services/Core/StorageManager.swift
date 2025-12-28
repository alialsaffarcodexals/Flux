/*
 File: StorageManager.swift
 Purpose: class StorageManager, func uploadProfilePicture
 Location: Services/StorageManager.swift
*/









import Foundation
import UIKit
import Cloudinary



/// Class StorageManager: Responsible for the lifecycle, state, and behavior related to StorageManager.
class StorageManager {
    
    static let shared = StorageManager()
    
    private let cloudName = "dwdxijm9c"
    private let uploadPreset = "flux–uploads_v2"

    private let profileFolder = "profiles"
    private let serviceFolder = "services"
    private let skillFolder = "skills"
    
    private let cloudinary: CLDCloudinary
    
    private init() {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        self.cloudinary = CLDCloudinary(configuration: config)
    }
    


/// @Description: Performs the uploadProfilePicture operation.
/// @Input: with data: Data; fileName: String; completion: @escaping (Result<String; Error>
/// @Output: Void)
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        uploadImageData(data, folder: profileFolder, publicId: fileName, completion: completion)
    }

    public func uploadServiceCoverImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        uploadImage(
            image,
            folder: serviceFolder,
            publicIdPrefix: "service_cover",
            completion: completion
        )
    }

    public func uploadSkillProofImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        uploadImage(
            image,
            folder: skillFolder,
            publicIdPrefix: "skill_proof",
            completion: completion
        )
    }

    private func uploadImage(
        _ image: UIImage,
        folder: String,
        publicIdPrefix: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(
                domain: "CloudinaryError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Unable to encode image data"]
            )
            completion(.failure(error))
            return
        }

        let publicId = "\(publicIdPrefix)_\(UUID().uuidString)"
        uploadImageData(data, folder: folder, publicId: publicId, completion: completion)
    }

    private func uploadImageData(
        _ data: Data,
        folder: String,
        publicId: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        
        let uploader = cloudinary.createUploader()
        let params = CLDUploadRequestParams()
        params.setFolder(folder)
        if let publicId = publicId, !publicId.isEmpty {
            params.setPublicId(publicId)
        }
        
        uploader.upload(data: data, uploadPreset: uploadPreset, params: params, progress: nil) { result, error in
            
            if let error = error {
                print("❌ Cloudinary Upload Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let result = result, let url = result.secureUrl {
                print("✅ Image Uploaded to Cloudinary: \(url)")
                completion(.success(url))
            } else {
                let unknownError = NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload successful but URL is missing"])
                completion(.failure(unknownError))
            }
        }
    }
}
