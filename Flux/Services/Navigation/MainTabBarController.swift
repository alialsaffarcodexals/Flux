import UIKit

/// MainTabBarController: Handles dynamic tab generation and switching between Seeker and Provider modes.
class MainTabBarController: UITabBarController {

    // MARK: - Properties
    private var currentUserRole: UserRole = .seeker

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        setupTabs(for: currentUserRole)
    }

    // MARK: - Tab Configuration
        
        func setupTabs(for role: UserRole) {
            currentUserRole = role
            var viewControllers: [UIViewController] = []

            // --- 1. Instantiate View Controllers ---
            
            // Common: Home
            // Storyboard ID: HomeNav
            let homeNav = instantiateViewController(storyboardName: "Home", storyboardID: "HomeNav")
            homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
            
            // Common: Messages
            // Storyboard ID: ChatNavigationController
            let messagesNav = instantiateViewController(storyboardName: "Chat", storyboardID: "ChatNavigationController")
            messagesNav.tabBarItem = UITabBarItem(title: "Messages", image: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"))

            if role == .seeker {
                // --- Seeker Mode (4 Tabs) ---
                
                // Seeker: Booking
                // Storyboard ID: SeekerBookingNavigationController
                let bookingNav = instantiateViewController(storyboardName: "Requests-seeker", storyboardID: "SeekerBookingNavigationController")
                bookingNav.tabBarItem = UITabBarItem(title: "Booking", image: UIImage(systemName: "calendar"), selectedImage: UIImage(systemName: "calendar.circle.fill"))
                
                // Seeker: Profile
                // Storyboard ID: SeekerProfileNavigationController
                let profileNav = instantiateViewController(storyboardName: "SeekerProfile", storyboardID: "SeekerProfileNavigationController")
                profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
                
                // Order: Home, Booking, Messages, Profile
                viewControllers = [homeNav, bookingNav, messagesNav, profileNav]
                
            } else {
                // --- Provider Mode (5 Tabs) ---
                
                // Provider: Requests
                // Storyboard ID: ProviderRequestsVC
                let requestsVC = instantiateViewController(storyboardName: "ProviderRequests", storyboardID: "ProviderRequestsVC")
                requestsVC.tabBarItem = UITabBarItem(title: "Requests", image: UIImage(systemName: "list.clipboard"), selectedImage: UIImage(systemName: "list.clipboard.fill"))
                
                // Provider: Management
                // Storyboard ID: ProviderManagementViewController
                let managementVC = instantiateViewController(storyboardName: "ProviderManagement", storyboardID: "ProviderManagementViewController")
                managementVC.tabBarItem = UITabBarItem(title: "Management", image: UIImage(systemName: "briefcase"), selectedImage: UIImage(systemName: "briefcase.fill"))
                
                // Provider: Profile
                // Storyboard ID: ProviderProfileNavigationController
                let providerProfileNav = instantiateViewController(storyboardName: "ProviderProfile", storyboardID: "ProviderProfileNavigationController")
                providerProfileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.crop.circle"), selectedImage: UIImage(systemName: "person.crop.circle.fill"))
                
                // Order: Home, Requests, Management, Messages, Profile
                viewControllers = [homeNav, requestsVC, managementVC, messagesNav, providerProfileNav]
            }
            
            // --- 2. Set View Controllers ---
            self.viewControllers = viewControllers
            
            // --- 3. UI Appearance (Optional but recommended) ---
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            
            self.tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                self.tabBar.scrollEdgeAppearance = appearance
            }
            self.tabBar.tintColor = UIColor.systemBlue
        }
    
    /// Switches the user role and updates the tabs, preserving the Profile tab selection.
    /// - Parameter role: The new role to switch to.
    func switchRole(to role: UserRole) {
        guard role != currentUserRole else { return }
        
        setupTabs(for: role)
        
        // Automatically select the Profile Tab
        // Seeker Profile Index: 3
        // Provider Profile Index: 4
        if role == .seeker {
            selectedIndex = 3
        } else {
            selectedIndex = 4
        }
    }

    // MARK: - Helper Methods
    
    private func instantiateViewController(storyboardName: String, storyboardID: String) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        // Crash gracefully? Or just crash if missing as per dev requirements to catch issues early?
        // User asked to "verify using identifier". Safest is to instantiate.
        return storyboard.instantiateViewController(withIdentifier: storyboardID)
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    // Implement delegate methods if needed for custom behavior on tab selection
}
