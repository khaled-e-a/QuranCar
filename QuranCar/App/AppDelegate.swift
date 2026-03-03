//
//  AppDelegate.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import UIKit
import CarPlay
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Tracker is now handled in QuranCarApp via scenePhase
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if connectingSceneSession.role == .carTemplateApplication {
            let config = UISceneConfiguration(
                name: "CarPlay Configuration",
                sessionRole: connectingSceneSession.role
            )
            config.delegateClass = CarPlaySceneDelegate.self
            return config
        }

        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Handled in QuranCarApp
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Handled in QuranCarApp
    }
}
