/// File: SceneDelegate.swift
/// Purpose: Class SceneDelegate, func scene, func sceneDidDisconnect, func sceneDidBecomeActive, func sceneWillResignActive, func sceneWillEnterForeground, func sceneDidEnterBackground, func changeRootViewController.
/// Location: App/SceneDelegate.swift

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // 1. Check if authenticated
        if let authUser = Auth.auth().currentUser {
            
            // 2. Use the Repository to get the User Model
            UserRepository.shared.getUser(uid: authUser.uid) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let user):
                    // 3. Determine where to go based on Role & Mode
                    self.navigateBasedOnRole(user: user)
                    
                case .failure(let error):
                    print("Error fetching user profile: \(error.localizedDescription)")
                    // If we can't get the user profile, fallback to login
                    self.navigateToLogin()
                }
            }
        } else {
            // Not logged in
            navigateToLogin()
        }
        
        window?.makeKeyAndVisible()
    }

    // MARK: - Navigation Logic
    
    func navigateBasedOnRole(user: User) {
        let storyboardID: String
        
        switch user.role {
        case .admin:
            storyboardID = "AdminNavigationController"
            
        case .seeker, .provider:
            storyboardID = "HomeNav"
            

//            // Check which mode they were last in
//            if let mode = user.activeProfileMode, mode == .sellerMode {
//                storyboardID = "ProviderHomeVC" // ID for the Dashboard showing incoming jobs
//            } else {
//                // If .buyerMode (or nil), they act like a seeker
//                storyboardID = "SeekerHomeVC"
//            }
        }
        
        launchViewController(withID: storyboardID)
    }
    
    func launchViewController(withID id: String) {
        // Ensure this runs on the Main Thread because we are updating UI
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Home", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: id)
            self.window?.rootViewController = vc
        }
    }
    
    func navigateToLogin() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            // Assuming the initial VC in storyboard is the Login screen
            if let loginVC = storyboard.instantiateInitialViewController() {
                self.window?.rootViewController = loginVC
            }
        }
    }

    /// Handles the sceneDidDisconnect lifecycle event.
    /// - Parameter scene: The scene that was disconnected.
    /// - Returns: Void
    func sceneDidDisconnect(_ scene: UIScene) {
        // Performs the sceneDidDisconnect operation.
    }

    /// Handles the sceneDidBecomeActive lifecycle event.
    /// - Parameter scene: The scene that became active.
    /// - Returns: Void
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Performs the sceneDidBecomeActive operation.
    }

    /// Handles the sceneWillResignActive lifecycle event.
    /// - Parameter scene: The scene that will resign active.
    /// - Returns: Void
    func sceneWillResignActive(_ scene: UIScene) {
        // Performs the sceneWillResignActive operation.
    }

    /// Handles the sceneWillEnterForeground lifecycle event.
    /// - Parameter scene: The scene that will enter foreground.
    /// - Returns: Void
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Performs the sceneWillEnterForeground operation.
    }

    /// Handles the sceneDidEnterBackground lifecycle event.
    /// - Parameter scene: The scene that entered background.
    /// - Returns: Void
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Performs the sceneDidEnterBackground operation.
    }

    /// Changes the root view controller of the window.
    /// - Parameters:
    ///   - vc: The new root view controller.
    ///   - animated: A Boolean indicating whether the transition is animated. Default is true.
    /// - Returns: Void
    func changeRootViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let window = self.window else { return }

        window.rootViewController = vc

        if animated {
            UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromRight, animations: nil, completion: nil)
        }
    }
}
