//
//  AppDelegate.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import UIKit
import QuranKit
import AppStructureFeature
import Logging
import CarPlay

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Logger.debug("Documents directory: \(FileManager.documentsURL)")

        // // Initialize the container
        // let _ = Container.shared

        // Task {
        //     // Eagerly load download manager to handle any background downloads.
        //     await Container.shared.downloadManager.start()

        //     // Begin fetching resources immediately after download manager is initialized.
        //     await Container.shared.readingResources.startLoadingResources()
        // }

        return true
    }

    // func application(
    //     _ application: UIApplication,
    //     handleEventsForBackgroundURLSession identifier: String,
    //     completionHandler: @escaping () -> Void
    // ) {
    //     let downloadManager = Container.shared.downloadManager
    //     downloadManager.setBackgroundSessionCompletion(completionHandler)
    // }

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
}