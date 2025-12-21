/*
 File: AppNavigator.swift
 Purpose: class AppNavigator, func navigateToRoleBasedHome, func navigateToSeekerProfile, func navigateToProviderProfile, func navigateToHome, func setRoot
 Location: Services/AppNavigator.swift
*/









import UIKit



/// Class AppNavigator: Responsible for the lifecycle, state, and behavior related to AppNavigator.
class AppNavigator {
    
    
    static let shared = AppNavigator()
    
    private init() {}
    
    
    


/// @Description: Performs the navigateToRoleBasedHome operation.
/// @Input: role: String
/// @Output: Void
    func navigateToRoleBasedHome(role: String) {
        print("🧭 Navigating based on role: \(role)")
        
        switch role {
        case "Seeker":
            navigateToSeekerProfile()
        case "Provider":
            navigateToProviderProfile()
        case "Admin":
            
             navigateToHome()
        default:
            navigateToHome()
        }
    }
    
    
    
    


/// @Description: Performs the navigateToSeekerProfile operation.
/// @Input: None
/// @Output: Void
    private func navigateToSeekerProfile() {
        let storyboard = UIStoryboard(name: "SeekerProfile", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "SeekerProfileViewController") as? SeekerProfileViewController {
            setRoot(viewController: vc)
        } else {
            print("🔴 Error: SeekerProfileViewController ID not found.")
        }
    }
    
    


/// @Description: Performs the navigateToProviderProfile operation.
/// @Input: None
/// @Output: Void
    private func navigateToProviderProfile() {
        let storyboard = UIStoryboard(name: "ProviderProfile", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "ProviderMainProfileVC") as? ProviderMainProfileVC {
            setRoot(viewController: vc)
        } else {
            print("🔴 Error: ProviderMainProfileVC ID not found.")
        }
    }
    
    


/// @Description: Performs the navigateToHome operation.
/// @Input: None
/// @Output: Void
    private func navigateToHome() {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "HomeFeedViewController") as? HomeFeedViewController {
            setRoot(viewController: vc)
        } else {
            print("🔴 Error: HomeFeedViewController ID not found.")
        }
    }
    
    
    


/// @Description: Performs the setRoot operation.
/// @Input: viewController: UIViewController
/// @Output: Void
    private func setRoot(viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        
        
        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromRight, animations: nil, completion: nil)
    }
}
