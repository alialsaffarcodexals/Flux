import Foundation
import UIKit
import Cloudinary

class StorageManager {
    
    static let shared = StorageManager()
    
    private let cloudName = "dsleqotkq"
    private let uploadPreset = "flux_uploads"
    
    private let cloudinary: CLDCloudinary
    
    private init() {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        self.cloudinary = CLDCloudinary(configuration: config)
    }
    
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
