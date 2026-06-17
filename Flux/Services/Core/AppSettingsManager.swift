import UIKit
import Foundation
import ObjectiveC

/// Manages app-wide settings: theme and font size
class AppSettingsManager {
    
    static let shared = AppSettingsManager()
    private init() {}
    
    // MARK: - UserDefaults Keys
    private let themeKey = "AppTheme"
    private let fontSizeKey = "AppFontSize"
    
    // MARK: - Theme Management
    
    enum AppTheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        
        var userInterfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }
    
    var currentTheme: AppTheme {
        get {
            if let saved = UserDefaults.standard.string(forKey: themeKey),
               let theme = AppTheme(rawValue: saved) {
                print("Loaded saved theme: \(theme.rawValue)")
                return theme
            }
            print("Using default theme: Light")
            return .light // Default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
            print("Theme changed to: \(newValue.rawValue)")
            applyTheme()
        }
    }
    
    func applyTheme(to window: UIWindow? = nil) {
        let targetWindow: UIWindow?
        
        if let window = window {
            targetWindow = window
        } else {
            // Fallback to finding the window
            targetWindow = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
        }
        
        guard let window = targetWindow else {
            print("Could not find window to apply theme")
            return
        }
        
        let style = currentTheme.userInterfaceStyle
        window.overrideUserInterfaceStyle = style
        print("Applied theme style: \(style == .dark ? "Dark" : "Light")")
    }
    
    // MARK: - Font Size Management
    
    enum FontSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var scaleFactor: CGFloat {
            switch self {
            case .small:
                return 0.9
            case .medium:
                return 1.0
            case .large:
                return 1.15
            }
        }
    }
    
    var currentFontSize: FontSize {
        get {
            if let saved = UserDefaults.standard.string(forKey: fontSizeKey),
               let size = FontSize(rawValue: saved) {
                return size
            }
            return .medium // Default
        }
        set {
            let oldValue = currentFontSize
            
            // Prevent re-applying the same size
            if newValue == oldValue {
                print("Font size unchanged: \(newValue.rawValue) (already selected)")
                return
            }
            
            UserDefaults.standard.set(newValue.rawValue, forKey: fontSizeKey)
            
            // Verify it was saved
            let savedValue = UserDefaults.standard.string(forKey: fontSizeKey) ?? "nil"
            print("Selected font size: \(newValue.rawValue)")
            print("UserDefaults fontSizeKey saved: \(savedValue)")
            print("currentFontSize now: \(newValue.rawValue) (was: \(oldValue.rawValue))")
            
            // Post notification
            NotificationCenter.default.post(name: AppNotifications.fontSizeDidChange, object: nil)
            print("Posted AppNotifications.fontSizeDidChange notification")
            
            // Apply fonts app-wide immediately
            applyFontsAppWide()
        }
    }
    
    /// Applies fonts to all visible view controllers in the app
    /// Applies fonts to all visible view controllers in the app
    private func applyFontsAppWide() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Get ALL loaded view controllers in the hierarchy
            let allControllers = self.getAllViewControllers(root: rootViewController)
            
            // Apply font to each controller's view
            for vc in allControllers {
                if vc.isViewLoaded {
                    self.applyFonts(to: vc.view)
                }
            }
            
            print("Applied fonts app-wide to \(allControllers.count) controllers")
        }
    }
    
    /// Recursively finds all view controllers from a root
    private func getAllViewControllers(root: UIViewController) -> [UIViewController] {
        var controllers: [UIViewController] = [root]
        
        // 1. Presented View Controllers (Modals)
        if let presented = root.presentedViewController {
            controllers.append(contentsOf: getAllViewControllers(root: presented))
        }
        
        // 2. Navigation Stack
        if let navController = root as? UINavigationController {
            for vc in navController.viewControllers {
                controllers.append(contentsOf: getAllViewControllers(root: vc))
            }
        }
        
        // 3. Tab Bar Controllers
        if let tabBarController = root as? UITabBarController, let tabs = tabBarController.viewControllers {
            for vc in tabs {
                controllers.append(contentsOf: getAllViewControllers(root: vc))
            }
        }
        
        // 4. Child View Controllers (Container Views)
        for child in root.children {
            if !controllers.contains(child) {
                controllers.append(contentsOf: getAllViewControllers(root: child))
            }
        }
        
        return controllers
    }
    
    /// Returns a scaled font based on current font size setting
    func scaledFont(baseFont: UIFont) -> UIFont {
        let scaledSize = baseFont.pointSize * currentFontSize.scaleFactor
        return UIFont(descriptor: baseFont.fontDescriptor, size: scaledSize)
    }
    
    // MARK: - Font Application
    
    // Associated object key for storing base font size
    private struct AssociatedKeys {
        static var baseFontSize = "baseFontSize"
    }
    
    /// Stores the base font size for a UI element (used to prevent cumulative scaling)
    private func setBaseFontSize(_ size: CGFloat, for element: AnyObject) {
        objc_setAssociatedObject(element, &AssociatedKeys.baseFontSize, size, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// Retrieves the base font size for a UI element, or calculates it from current font
    private func getBaseFontSize(for element: AnyObject, currentFont: UIFont) -> CGFloat {
        if let stored = objc_getAssociatedObject(element, &AssociatedKeys.baseFontSize) as? CGFloat {
            // Base size already stored - use it
            return stored
        }
        
        // First time seeing this element:
        // Assume the current font on the view IS the base size (e.g. from storyboard or code default)
        // We must strictly adhere to this to avoid cumulative scaling or wrong reverse-engineering
        let currentSize = currentFont.pointSize
        setBaseFontSize(currentSize, for: element)
        return currentSize
    }
    
    /// Applies scaled fonts to all UI elements in a view hierarchy
    func applyFonts(to view: UIView) {
        applyFontsRecursive(to: view)
    }
    
    private func applyFontsRecursive(to view: UIView) {
        // Apply to labels
        if let label = view as? UILabel, let font = label.font {
            let baseSize = getBaseFontSize(for: label, currentFont: font)
            let scaledSize = baseSize * currentFontSize.scaleFactor
            if label.font.pointSize != scaledSize {
                 label.font = UIFont(descriptor: font.fontDescriptor, size: scaledSize)
            }
        }
        
        // Apply to buttons
        if let button = view as? UIButton, let titleLabel = button.titleLabel, let font = titleLabel.font {
            let baseSize = getBaseFontSize(for: button, currentFont: font)
            let scaledSize = baseSize * currentFontSize.scaleFactor
             if titleLabel.font.pointSize != scaledSize {
                titleLabel.font = UIFont(descriptor: font.fontDescriptor, size: scaledSize)
            }
        }
        
        // Apply to text fields
        if let textField = view as? UITextField, let font = textField.font {
            let baseSize = getBaseFontSize(for: textField, currentFont: font)
            let scaledSize = baseSize * currentFontSize.scaleFactor
            if textField.font?.pointSize != scaledSize {
                textField.font = UIFont(descriptor: font.fontDescriptor, size: scaledSize)
            }
        }
        
        // Apply to text views
        if let textView = view as? UITextView, let font = textView.font {
            let baseSize = getBaseFontSize(for: textView, currentFont: font)
            let scaledSize = baseSize * currentFontSize.scaleFactor
            if textView.font?.pointSize != scaledSize {
                 textView.font = UIFont(descriptor: font.fontDescriptor, size: scaledSize)
            }
        }
        
        // Recursively apply to subviews
        for subview in view.subviews {
            applyFontsRecursive(to: subview)
        }
    }
}

// MARK: - Notification Names
/// App-specific notification names using Foundation.Notification to avoid collision with Flux.Notification model
enum AppNotifications {
    static let fontSizeDidChange = Foundation.Notification.Name("fontSizeDidChange")
}
