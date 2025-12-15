//
//  StorageManager.swift
//  Flux
//
//  Created by Ali Hussain Ali Alsaffar on 06/12/2025.
//

import Foundation
import FirebaseStorage
import UIKit

class StorageManager {
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    private init() {}
    
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let fileRef = storage.child("images/profile_pictures/\(fileName)")
        
        fileRef.putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            fileRef.downloadURL { url, error in
                guard let url = url else {
                    completion(.failure(error ?? NSError(domain: "FluxStorage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to download URL"])))
                    return
                }
                
                completion(.success(url.absoluteString))
            }
        }
    }
}
