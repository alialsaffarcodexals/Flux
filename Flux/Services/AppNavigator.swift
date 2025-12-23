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
                // Phase 2: The seeker always navigates to the buying interface.
                navigateToSeekerTabs()
                
            case .provider:
                // Phase 5: The provider depends on the last mode they were in.
                if let mode = user.activeProfileMode, mode == .sellerMode {
                    navigateToProviderTabs() // Selling interface
                } else {
                    navigateToSeekerTabs() // Buying interface (Graphic Designer hiring a cleaner)
                }
                
            case .admin:
                // navigateToAdmin()
                navigateToSeekerTabs()
            }
        }
    
    // MARK: - 1. Seeker Navigation
    private func navigateToSeekerTabs() {
        // ⚠️ Note: Change "Home" to the name of the storyboard containing the seeker's TabBar.
        let storyboard = UIStoryboard(name: "SeekerProfile", bundle: nil)
        
        // Look for the Tab Bar Controller by the ID you set.
        if let tabBarVC = storyboard.instantiateViewController(withIdentifier: "SeekerTabBarController") as? UITabBarController {
            setRoot(viewController: tabBarVC)
        } else {
            print("🔴 Error: Could not find 'SeekerTabBarController' in Storyboard.")
        }
    }
    
    // MARK: - 2. Provider Navigation
    private func navigateToProviderTabs() {
        // ⚠️ Note: Change "ProviderProfile" to the name of the storyboard containing the provider's TabBar.
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
        
        // Smooth transition animation.
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}

