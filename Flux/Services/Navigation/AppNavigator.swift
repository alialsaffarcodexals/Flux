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
//                    //DummyDataSeeder.shared.seedIfNeeded()
//                    #endif
            loadMainTabBar(for: user, initialIndex: destinationTab)
        }
    }
    
    // MARK: - Admin Navigation
        private func loadAdminInterface() {
            let storyboard = UIStoryboard(name: "AdminTools", bundle: nil) // Must match file name "AdminTools.storyboard"
            
            // Use the Storyboard ID we set in Step 3
            guard let adminNav = storyboard.instantiateViewController(withIdentifier: "AdminTabBarController") as? UITabBarController else {
                print("🔴 Error: Could not find 'AdminTabBarController' in AdminTools.storyboard")
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
        
        // Ensure theme is applied when changing root
        AppSettingsManager.shared.applyTheme()
        
        // Apply fonts to the new root view controller
        DispatchQueue.main.async {
            AppSettingsManager.shared.applyFonts(to: viewController.view)
        }

        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }

    // MARK: - Provider Management Navigation
    
    func navigateToProviderAvailability() {
        let storyboard = UIStoryboard(name: "ProviderManagement", bundle: nil)
        // Note: Ensure the VC in storyboard has ID "ProviderAvailabilityCalendarViewController"
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ProviderAvailabilityCalendarViewController") as? ProviderAvailabilityCalendarViewController else {
            print("🔴 Error: Could not find 'ProviderAvailabilityCalendarViewController' in ProviderManagement.storyboard")
            return
        }
        // In a real app, you might push this if inside a navigation controller, or set as root for testing
        // For now, let's assume it's part of the tab bar or pushed.
        // If standalone test:
        // setRoot(viewController: UINavigationController(rootViewController: vc))
        
        // Since the prompt asks for "Route entry", but we use a TabBar, this might just be helper for deep linking or manual transition.
        // We will assume the caller handles the presentation strategy (e.g. push or present), or we can return the VC.
        // But to stick to the pattern, let's provide a method to get it, or handle transition if we have a top nav.
        
        // Simplest: Just return it? No, AppNavigator seems to control the window root.
        // Let's print for now as we don't have a clear "Manage" tab yet in the main tab bar logic shown in the file.
        // But I will add a method that CAN be called.
    }
    
    func getProviderAvailabilityViewController() -> UIViewController? {
        let storyboard = UIStoryboard(name: "ProviderManagement", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ProviderAvailabilityCalendarViewController")
    }

    // MARK: - Service Packages Navigation
    
    func getServicePackagesListViewController() -> UIViewController? {
        let storyboard = UIStoryboard(name: "ServicePackages", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ServicePackagesListViewController")
    }
    
    func getServicePackageEditorViewController(package: ServicePackage?) -> UIViewController? {
        let storyboard = UIStoryboard(name: "ServicePackages", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ServicePackageEditorViewController") as? ServicePackageEditorViewController else {
            return nil
        }
        // Initialize VM with package
        vc.viewModel = ServicePackageEditorViewModel(package: package)
        return vc
    }

}
