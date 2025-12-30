/// File: SceneDelegate.swift
/// Purpose: Class SceneDelegate, func scene, func sceneDidDisconnect, func sceneDidBecomeActive, func sceneWillResignActive, func sceneWillEnterForeground, func sceneDidEnterBackground, func changeRootViewController.
/// Location: App/SceneDelegate.swift

import UIKit

/// Class SceneDelegate: Responsible for the lifecycle, state, and behavior related to SceneDelegate.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Handles the scene connection lifecycle.
    /// - Parameters:
    ///   - scene: The scene to connect.
    ///   - session: The session being connected.
    ///   - connectionOptions: Additional options for configuration.
    /// - Returns: Void
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Required Behavior: Always start at Authentication flow
        print("🚀 App Launched. Setting Root VC to Authentication Navigation Controller.")
        
        let storyboard = UIStoryboard(name: "Authentication", bundle: nil)
        
        // "AuthenticationNC" is the initial Navigation Controller in Authentication.storyboard
        guard let authNav = storyboard.instantiateViewController(withIdentifier: "AuthenticationNC") as? UINavigationController else {
            print("🔴 Error: Could not find 'AuthenticationNC' (Auth Nav) in Authentication.storyboard")
            return
        }
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = authNav
        self.window = window
        window.makeKeyAndVisible()
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
