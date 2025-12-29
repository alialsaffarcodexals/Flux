import UIKit

// specific tag to identify our spinner view so we can remove it later
private let loadingIndicatorTag = 999999

extension UIViewController {
    
    /// Adds a loading spinner to the center of the current view controller
    func showLoadingIndicator() {
        // Prevent adding multiple spinners if one already exists
        if view.viewWithTag(loadingIndicatorTag) != nil { return }
        
        // Setup the activity indicator
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.tag = loadingIndicatorTag
        indicator.color = .gray // You can change this to your app's theme color
        indicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to main view
        view.addSubview(indicator)
        
        // Center constraints
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        indicator.startAnimating()
    }
    
    /// Removes the loading spinner from the view
    func hideLoadingIndicator() {
        // Find the view by tag and remove it
        if let indicator = view.viewWithTag(loadingIndicatorTag) as? UIActivityIndicatorView {
                    indicator.stopAnimating()
                    indicator.removeFromSuperview()
                }
    }
}
