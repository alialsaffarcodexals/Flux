/// File: SceneDelegate.swift
/// Purpose: Class SceneDelegate, func scene, func sceneDidDisconnect, func sceneDidBecomeActive, func sceneWillResignActive, func sceneWillEnterForeground, func sceneDidEnterBackground, func changeRootViewController.
/// Location: App/SceneDelegate.swift

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Setup Window
        let window = UIWindow(windowScene: windowScene)
        
        // Fix Black Screen: Set an initial Loading View Controller immediately
        window.rootViewController = LoadingViewController()
        
        self.window = window
        window.makeKeyAndVisible()
        
        
        AppNavigator.shared.startApp()
        
        
        
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
}
