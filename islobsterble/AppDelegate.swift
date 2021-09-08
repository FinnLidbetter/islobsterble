//
//  AppDelegate.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-03.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import UIKit
import SwiftUI

//let ROOT_URL = "http://127.0.0.1:5000/"
let ROOT_URL = "https://slobsterble.finnlidbetter.com/"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.applicationIconBadgeNumber = 0
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // Handle remote notification registration.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenComponents = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let deviceTokenString = tokenComponents.joined()

        self.setDeviceTokenInTracker(tokenString: deviceTokenString)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
    }

    func setDeviceTokenInTracker(tokenString: String) {
        let firstScene = UIApplication.shared.connectedScenes.first
        guard let firstSceneDelegate: SceneDelegate = (firstScene?.delegate as? SceneDelegate) else {
            return
        }
        firstSceneDelegate.notificationTracker.deviceTokenString = tokenString
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let gameId = userInfo["game_id"] as? String else {
            completionHandler()
            return
        }
        
        let firstScene = UIApplication.shared.connectedScenes.first
        guard let firstSceneDelegate : SceneDelegate = (firstScene?.delegate as? SceneDelegate) else {
            completionHandler()
            return
        }
        firstSceneDelegate.notificationTracker.refreshGames.insert(gameId)

        // Always call the completion handler when done.
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
             willPresent notification: UNNotification,
             withCompletionHandler completionHandler:
                @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        guard let gameId = userInfo["game_id"] as? String else {
            completionHandler(UNNotificationPresentationOptions(rawValue: 0))
            return
        }
        
        let firstScene = UIApplication.shared.connectedScenes.first
        guard let firstSceneDelegate : SceneDelegate = (firstScene?.delegate as? SceneDelegate) else {
            completionHandler(UNNotificationPresentationOptions(rawValue: 0))
            return
        }
        firstSceneDelegate.notificationTracker.refreshGames.insert(gameId)

        // Always call the completion handler when done.
        completionHandler(UNNotificationPresentationOptions(rawValue: 0))
    }

}

