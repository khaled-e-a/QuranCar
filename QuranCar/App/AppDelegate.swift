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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("Documents directory: ", FileManager.documentsURL)

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
}