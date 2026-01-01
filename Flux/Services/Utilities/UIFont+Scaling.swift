import UIKit

extension UIFont {
    
    /// Returns a scaled font based on the current app font size setting
    static func scaledSystemFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight)
        return AppSettingsManager.shared.scaledFont(baseFont: baseFont)
    }
    
    /// Returns a scaled version of the current font
    var scaled: UIFont {
        return AppSettingsManager.shared.scaledFont(baseFont: self)
    }
}

