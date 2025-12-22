import UIKit

class AppNavigator {
    
    static let shared = AppNavigator()
    
    private init() {}
    
    // MARK: - Main Router
    // MARK: - Main Router Logic
        func navigate(user: User) {
            print("🧭 Navigating for user: \(user.name), Role: \(user.role.rawValue)")
            
            switch user.role {
            case .seeker:
                // المرحلة 2: الباحث دائماً يذهب لواجهة الشراء
                navigateToSeekerTabs()
                
            case .provider:
                // المرحلة 5: المزود يعتمد على آخر وضع (Mode) كان فيه
                if let mode = user.activeProfileMode, mode == .sellerMode {
                    navigateToProviderTabs() // واجهة البيع
                } else {
                    navigateToSeekerTabs() // واجهة الشراء (Graphic Designer hiring a cleaner)
                }
                
            case .admin:
                // navigateToAdmin()
                navigateToSeekerTabs()
            }
        }
    
    // MARK: - 1. Seeker Navigation
    private func navigateToSeekerTabs() {
        // ⚠️ ملاحظة: غير اسم "Home" إلى اسم الـ Storyboard الموجود فيه الـ TabBar الخاص بالباحث
        let storyboard = UIStoryboard(name: "SeekerProfile", bundle: nil)
        
        // نبحث عن الـ Tab Bar Controller بواسطة الـ ID الذي وضعته
        if let tabBarVC = storyboard.instantiateViewController(withIdentifier: "SeekerTabBarController") as? UITabBarController {
            setRoot(viewController: tabBarVC)
        } else {
            print("🔴 Error: Could not find 'SeekerTabBarController' in Storyboard.")
        }
    }
    
    // MARK: - 2. Provider Navigation
    private func navigateToProviderTabs() {
        // ⚠️ ملاحظة: غير اسم "ProviderProfile" إلى اسم الـ Storyboard الموجود فيه الـ TabBar الخاص بالمزود
        let storyboard = UIStoryboard(name: "ProviderProfile", bundle: nil)
        
        if let tabBarVC = storyboard.instantiateViewController(withIdentifier: "ProviderTabBarController") as? UITabBarController {
            setRoot(viewController: tabBarVC)
        } else {
            print("🔴 Error: Could not find 'ProviderTabBarController' in Storyboard.")
        }
    }
    
    // MARK: - Helper: Change Root
    private func setRoot(viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        
        // حركة انتقال ناعمة
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}
