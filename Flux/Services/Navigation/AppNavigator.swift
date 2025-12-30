import UIKit

class AppNavigator {
    
    static let shared = AppNavigator()
    private init() {}
    
    // MARK: - Navigation Entry Point
    func navigate(user: User) {
                if user.role == .admin {
                    // Route to Admin Flow
                    loadAdminInterface()
                } else {
                    // Route to Standard App (Seeker/Provider)
                    loadMainTabBar(for: user)
                }
    }
    
    // MARK: - Admin Navigation
        private func loadAdminInterface() {
            let storyboard = UIStoryboard(name: "AdminTools", bundle: nil) // Must match file name "AdminTools.storyboard"
            
            // Use the Storyboard ID we set in Step 3
            guard let adminNav = storyboard.instantiateViewController(withIdentifier: "AdminNavigationController") as? UINavigationController else {
                print("🔴 Error: Could not find 'AdminNavigationController' in AdminTools.storyboard")
                return
            }
            
            setRoot(viewController: adminNav)
        }
    
    private func loadMainTabBar(for user: User) {
        print("🔄 Switching to MainTabBarController for user: \(user.firstName) (\(user.role.rawValue))")
        
        // 1. Instantiate MainTabBarController programmatically
        let mainTabBarController = MainTabBarController()
        
        // 2. Configure Tabs based on User Role
        mainTabBarController.setupTabs(for: user.role)
        
        // 3. Handle Active Profile Mode / Initial Tab Selection
        // If the user was in Seller Mode (Provider), we might want to switch them to that context.
        // MainTabBarController.setupTabs(for: user.role) already sets up the correct tabs.
        // If we want to strictly follow "activeProfileMode should still work normally", 
        // we ensure the tabs are correct (which they are by passing user.role).
        
        // Optional: If you want to force them to the profile tab or specific tab based on state:
        // if user.role == .provider && user.activeProfileMode == .sellerMode {
        //      mainTabBarController.selectedIndex = 4 // Index of Profile in Provider mode
        // }
        // For now, defaulting to Home (Index 0) is standard for a fresh login/launch transition.
        
        // 4. Set as Root
        setRoot(viewController: mainTabBarController)
    }
    
    // MARK: - Auth Navigation
    
    func navigateToAuth() {
        print("🔙 Navigating to Authentication Flow")
        let storyboard = UIStoryboard(name: "Authentication", bundle: nil)
        guard let authNav = storyboard.instantiateViewController(withIdentifier: "AuthenticationNC") as? UINavigationController else {
            return
        }
        setRoot(viewController: authNav)
    }
    
    /// Public method to switch to Authentication flow (Logout/Reset).
    func switchToAuthentication() {
        // Reuse the existing logic which already handles Storyboard instantiation and Root switching safely.
        navigateToAuth()
    }
    
    // MARK: - Helper: Change Root
    private func setRoot(viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}
