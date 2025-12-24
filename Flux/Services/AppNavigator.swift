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
        // 1. Load the Global Tab Bar (currently living in SeekerProfile.storyboard)
        let storyboard = UIStoryboard(name: "SeekerProfile", bundle: nil)
        
        guard let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "SeekerTabBarController") as? UITabBarController else {
            print("🔴 Error: Could not find 'SeekerTabBarController'.")
            return
        }
        
        // 2. Configure the Profile Tab (Index 3) based on User Role/Mode
        var shouldSelectProfileTab = false
        
        if let viewControllers = mainTabBarController.viewControllers, viewControllers.count > 3 {
            
            // The 4th tab (Index 3) is the Profile Navigation Controller
            if let profileNav = viewControllers[3] as? UINavigationController {
                // This function now returns 'true' if we are in Provider Mode
                shouldSelectProfileTab = configureProfileTab(navigationController: profileNav, user: user)
            }
        }
        
        // 3. FIX: If in Seller Mode, explicitly select the Profile Tab (Index 3)
        if shouldSelectProfileTab {
            mainTabBarController.selectedIndex = 3
        }
        
        // 4. Set as Root
        setRoot(viewController: mainTabBarController)
    }
    
    // MARK: - Profile Switching Logic
    /// Configures the profile tab and returns TRUE if the app should default to this tab (Provider Mode).
    private func configureProfileTab(navigationController: UINavigationController, user: User) -> Bool {
        
        // Check if user is in Seller Mode
        if user.role == .provider && user.activeProfileMode == .sellerMode {
            print("👤 Configuring Profile Tab: Provider Mode")
            
            // Load the Provider Profile VC from its specific storyboard
            let providerStoryboard = UIStoryboard(name: "ProviderProfile", bundle: nil)
            if let providerVC = providerStoryboard.instantiateViewController(withIdentifier: "ProviderMainProfileVC") as? UIViewController {
                // REPLACE the stack with the Provider Profile
                navigationController.setViewControllers([providerVC], animated: false)
            }
            return true // YES, select this tab
            
        } else {
            print("👤 Configuring Profile Tab: Seeker Mode")
            
            // Ensure Seeker VC is loaded (Standard behavior)
            let seekerStoryboard = UIStoryboard(name: "SeekerProfile", bundle: nil)
            if let seekerVC = seekerStoryboard.instantiateViewController(withIdentifier: "SeekerProfileViewController") as? UIViewController {
                navigationController.setViewControllers([seekerVC], animated: false)
            }
            return false // NO, stay on Home tab
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
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}
