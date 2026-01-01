///
/// File: AppDelegate.swift.
/// Purpose: Class AppDelegate, func application, func application, func application.
/// Location: App/AppDelegate.swift.
///


import FirebaseCore
import UIKit

/// Class AppDelegate: Responsible for the lifecycle, state, and behavior related to AppDelegate.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Handles app launch.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - launchOptions: A dictionary indicating the reason the app was launched (if any).
    /// - Returns: A Boolean value indicating whether the app launched successfully.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        // Enable app-wide font scaling
        UIViewController.swizzleFontScaling()
        
        return true
    }

    /// Called when a new scene session is being created.
    /// Use this method to select a configuration to create the new scene with.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - connectingSceneSession: The scene session being created.
    ///   - options: Additional options for configuring the scene.
    /// - Returns: A UISceneConfiguration object.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// Called when the user discards a scene session.
    /// If any sessions were discarded while the app was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - sceneSessions: The set of discarded scene sessions.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
        // No additional actions required when scene sessions are discarded.
    }
}
