/*
 File: SceneDelegate.swift
 Purpose: class SceneDelegate, func scene, func sceneDidDisconnect, func sceneDidBecomeActive, func sceneWillResignActive, func sceneWillEnterForeground, func sceneDidEnterBackground, func changeRootViewController
 Location: App/SceneDelegate.swift
*/
















import UIKit



/// Class SceneDelegate: Responsible for the lifecycle, state, and behavior related to SceneDelegate.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?




/// @Description: Performs the scene operation.
/// @Input: _ scene: UIScene; willConnectTo session: UISceneSession; options connectionOptions: UIScene.ConnectionOptions
/// @Output: Void
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }



/// @Description: Performs the sceneDidDisconnect operation.
/// @Input: _ scene: UIScene
/// @Output: Void
    func sceneDidDisconnect(_ scene: UIScene) {
        
        
        
        
    }



/// @Description: Performs the sceneDidBecomeActive operation.
/// @Input: _ scene: UIScene
/// @Output: Void
    func sceneDidBecomeActive(_ scene: UIScene) {
        
        
    }



/// @Description: Performs the sceneWillResignActive operation.
/// @Input: _ scene: UIScene
/// @Output: Void
    func sceneWillResignActive(_ scene: UIScene) {
        
        
    }



/// @Description: Performs the sceneWillEnterForeground operation.
/// @Input: _ scene: UIScene
/// @Output: Void
    func sceneWillEnterForeground(_ scene: UIScene) {
        
        
    }



/// @Description: Performs the sceneDidEnterBackground operation.
/// @Input: _ scene: UIScene
/// @Output: Void
    func sceneDidEnterBackground(_ scene: UIScene) {
        
        
        
    }

    


/// @Description: Performs the changeRootViewController operation.
/// @Input: _ vc: UIViewController; animated: Bool = true
/// @Output: Void
        func changeRootViewController(_ vc: UIViewController, animated: Bool = true) {
            guard let window = self.window else { return }
            
            window.rootViewController = vc
            
            if animated {
                UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromRight, animations: nil, completion: nil)
            }
        }

}

