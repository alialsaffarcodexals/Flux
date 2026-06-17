/*
 File: Extenstion.swift
 Purpose: Swift declarations for the Flux app.
 Location: Services/Extenstion.swift
*/
















import Foundation
import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    
    func loadImage(from urlString: String?, placeholder: UIImage? = nil) {
        self.image = nil // Reset old image
        
        // 1. Check if URL exists
        guard let urlString = urlString, let url = URL(string: urlString) else {
            self.image = placeholder
            return
        }
        
        // 2. Check Cache (Don't download if we already have it)
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        
        // 3. Download Image (Background Thread)
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let downloadedImage = UIImage(data: data) else {
                return
            }
            
            // 4. Save to Cache
            imageCache.setObject(downloadedImage, forKey: urlString as NSString)
            
            // 5. Update UI (Main Thread)
            DispatchQueue.main.async {
                self.image = downloadedImage
            }
        }.resume()
    }
}
