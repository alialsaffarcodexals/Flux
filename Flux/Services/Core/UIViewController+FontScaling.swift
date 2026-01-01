import UIKit
import ObjectiveC

public extension UIViewController {
    
    /// Enables automatic font scaling for all view controllers from the main bundle
    static func swizzleFontScaling() {
        // Exchange viewWillAppear
        let originalSelector = #selector(viewWillAppear(_:))
        let swizzledSelector = #selector(fontScaling_viewWillAppear(_:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            print("❌ Failed to swizzle viewWillAppear")
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        print("✅ UIViewController.viewWillAppear swizzled for font scaling")
    }
    
    @objc private func fontScaling_viewWillAppear(_ animated: Bool) {
        // Call original implementation (which is now this method due to swizzling)
        fontScaling_viewWillAppear(animated)
        
        // Only apply scaling to view controllers from our own bundle
        // This prevents messing with system view controllers (UIAlertController, etc.)
        // and ensures we only target the app's screens
        let bundle = Bundle(for: type(of: self))
        if bundle == Bundle.main {
            // Check if view is loaded just in case, though viewWillAppear implies it is
            if isViewLoaded {
                AppSettingsManager.shared.applyFonts(to: view)
            }
        }
    }
}
