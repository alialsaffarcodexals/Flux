/*
 File: AppDelegate.swift
 Purpose: class AppDelegate, func application, func application, func application
 Location: App/AppDelegate.swift
*/















import FirebaseCore
import UIKit



/// Class AppDelegate: Responsible for the lifecycle, state, and behavior related to AppDelegate.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {





/// @Description: Performs the application operation.
/// @Input: _ application: UIApplication; didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
/// @Output: Bool
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        return true
    }

    



/// @Description: Performs the application operation.
/// @Input: _ application: UIApplication; configurationForConnecting connectingSceneSession: UISceneSession; options: UIScene.ConnectionOptions
/// @Output: UISceneConfiguration
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }



/// @Description: Performs the application operation.
/// @Input: _ application: UIApplication; didDiscardSceneSessions sceneSessions: Set<UISceneSession>
/// @Output: Void
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
        
        
    }


}

