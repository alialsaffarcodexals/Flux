import UIKit
import FirebaseAuth

class AppNavigator {
    
    static let shared = AppNavigator()
    private init() {}
    
    // MARK: - Navigation Entry Point
    
    /// Called by SceneDelegate to decide where to start.
    func startApp() {
        if let user = FirebaseAuth.Auth.auth().currentUser {
            print("🚀 Found active session for UID: \(user.uid). Fetching profile...")
            
            // Fetch detailed user profile from Firestore
            UserRepository.shared.getUser(uid: user.uid) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let userData):
                    print("✅ Profile fetched. Navigating to App.")
                    DispatchQueue.main.async {
                        self.navigate(user: userData)
                    }
                case .failure(let error):
                    print("⚠️ Failed to fetch profile: \(error). Falling back to Auth.")
                    DispatchQueue.main.async {
                        self.navigateToAuth()
                    }
                }
            }
        } else {
            print("ℹ️ No active session. Navigate to Auth.")
            navigateToAuth()
        }
    }
    
    // ✅ UPDATE 1: Add 'destinationTab' parameter (default is nil)
    func navigate(user: User, destinationTab: Int? = nil) {
        if user.role == .admin {
            // Route to Admin Flow
            loadAdminInterface()
        } else {
            // Route to Standard App (Seeker/Provider)
//                    #if DEBUG
//                    DummyDataSeeder.shared.seedIfNeeded()
//                    #endif
            loadMainTabBar(for: user, initialIndex: destinationTab)
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
    
    // ✅ UPDATE 2: Handle the index in loadMainTabBar
    private func loadMainTabBar(for user: User, initialIndex: Int?) {
        print("🔄 Switching to MainTabBarController for user: \(user.firstName). Target Index: \(String(describing: initialIndex))")
        
        // 1. Instantiate MainTabBarController programmatically
        let mainTabBarController = MainTabBarController()
        
        // 2. Configure Tabs based on User Role
        mainTabBarController.setupTabs(for: user.role)
        
        // 3. Apply target index if provided (e.g., 4 for Provider Profile)
        if let index = initialIndex {
            mainTabBarController.selectedIndex = index
        }
        
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
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneDelegate = scene.delegate as? SceneDelegate,
            let window = sceneDelegate.window
        else {
            return
        }

        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }

}
