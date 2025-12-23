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
    
    private let cloudName = "dsleqotkq"
    private let uploadPreset = "flux_uploads"
    
    private let cloudinary: CLDCloudinary
    
    private init() {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        self.cloudinary = CLDCloudinary(configuration: config)
    }
    


/// @Description: Performs the uploadProfilePicture operation.
/// @Input: with data: Data; fileName: String; completion: @escaping (Result<String; Error>
/// @Output: Void)
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let uploader = cloudinary.createUploader()
        
        uploader.upload(data: data, uploadPreset: uploadPreset, params: nil, progress: nil) { result, error in
            
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
