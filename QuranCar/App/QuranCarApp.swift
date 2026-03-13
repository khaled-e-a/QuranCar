//
//  QuranCarApp.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import SwiftUI
import AVFoundation
import CarPlay

@main
struct QuranCarApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    // Manage singletons here to ensure they live for the app's lifetime
    @StateObject private var bookViewModel = BookViewModel.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var storeManager = StoreManager.shared

    init() {
        // We'll move the authentication to be user-triggered
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookViewModel)
                .environmentObject(notificationManager)
                .environmentObject(storeManager)
                .environmentObject(bookViewModel.audioManager)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                print("DEBUG: App Phase -> Active")
                notificationManager.trackAppUsage()
                Task {
                    await storeManager.checkHadiyaStatus()
                }
            case .background:
                print("DEBUG: App Phase -> Background")
                notificationManager.scheduleNotificationIfNeeded()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
