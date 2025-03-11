//
//  QuranCarApp.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import SwiftUI
import AVFoundation
import QuranKit
import CarPlay

@main
struct QuranCarApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        // We'll move the authentication to be user-triggered
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
