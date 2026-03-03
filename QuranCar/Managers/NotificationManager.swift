//
//  NotificationManager.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private enum UserDefaultsKeys {
        static let lastAppUsageTimestamp = "lastAppUsageTimestamp"
        static let notificationsEnabled = "notificationsEnabled"
    }

    private let notificationIdentifier = "qurancar_inactivity_reminder"
    private let inactivityThreshold: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds
    private let notificationHour = 14 // 2 PM
    private let notificationMinute = 0

    @Published var selectedTab: Tab = .memorize
    @Published var showingSoftPrompt = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isNotificationEnabled: Bool {
        didSet {
            defaults.set(isNotificationEnabled, forKey: UserDefaultsKeys.notificationsEnabled)
            if !isNotificationEnabled {
                cancelScheduledNotifications()
            }
        }
    }

    private override init() {
        // Initialize published properties before calling super.init()
        let savedValue = defaults.object(forKey: UserDefaultsKeys.notificationsEnabled)
        if savedValue == nil {
            self.isNotificationEnabled = true
            defaults.set(true, forKey: UserDefaultsKeys.notificationsEnabled)
        } else {
            self.isNotificationEnabled = defaults.bool(forKey: UserDefaultsKeys.notificationsEnabled)
        }

        super.init()

        // Check current authorization status
        Task {
            await checkAuthorizationStatus()
        }
        
        setupNotificationDelegate()
    }

    private func setupNotificationDelegate() {
        notificationCenter.delegate = self
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            Logger.error("NotificationManager: Failed to request authorization: \(error)")
            return false
        }
    }

    // MARK: - Usage Tracking

    func trackAppUsage() {
        let currentTimestamp = Date().timeIntervalSince1970
        defaults.set(currentTimestamp, forKey: UserDefaultsKeys.lastAppUsageTimestamp)
        print("LOGGING: NotificationManager -> Tracking app usage (Resetting badge and canceling)")

        // Reset badge count
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Cancel any scheduled notifications since user is now active
        cancelScheduledNotifications()
    }

    private func getLastUsageTimestamp() -> TimeInterval? {
        let timestamp = defaults.double(forKey: UserDefaultsKeys.lastAppUsageTimestamp)
        return timestamp > 0 ? timestamp : nil
    }

    private func timeSinceLastUsage() -> TimeInterval? {
        guard let lastUsage = getLastUsageTimestamp() else {
            return nil
        }
        return Date().timeIntervalSince1970 - lastUsage
    }

    // MARK: - Notification Scheduling

    func scheduleNotificationIfNeeded() {
        // Only schedule if notifications are enabled
        guard isNotificationEnabled else {
            print("LOGGING: NotificationManager -> Notifications disabled in settings")
            return
        }

        // Check authorization status
        Task { @MainActor in
            await checkAuthorizationStatus()

            guard authorizationStatus == .authorized else {
                print("LOGGING: NotificationManager -> Notifications NOT authorized (\(authorizationStatus))")
                return
            }

            // Always schedule a notification for 3 days in the future.
            await scheduleNotification()
        }
    }

    private func scheduleNotification() async {
        // Cancel any existing notifications first
        cancelScheduledNotifications()

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to continue your memorization"
        content.body = "You haven't opened QuranCar in a while. Continue your journey with the Quran."
        content.sound = .default
        content.badge = 1

        // Schedule for 3 days from now at 2 PM
        let calendar = Calendar.current
        let now = Date()
        
        // Add 3 days
        guard let threeDaysFromNow = calendar.date(byAdding: .day, value: 3, to: now) else {
            print("LOGGING: NotificationManager -> ERROR: Failed to calculate 3 days from now")
            return
        }
        
        var targetComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: threeDaysFromNow)
        targetComponents.hour = notificationHour
        targetComponents.minute = notificationMinute

        guard let triggerDate = calendar.date(from: targetComponents) else {
            print("LOGGING: NotificationManager -> ERROR: Failed to create trigger date")
            return
        }

        // Create trigger
        let finalComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: finalComponents, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        do {
            try await notificationCenter.add(request)
            print("LOGGING: NotificationManager -> SUCCESS: Scheduled reminder for \(triggerDate)")
        } catch {
            print("LOGGING: NotificationManager -> ERROR: Failed to schedule: \(error)")
        }
    }

    func cancelScheduledNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
        print("LOGGING: NotificationManager -> Cancelled scheduled reminders")
    }

    func scheduleTestNotification() async {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from QuranCar. It works!"
        content.sound = .default
        content.badge = 1

        // Create trigger for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier + "_test",
            content: content,
            trigger: trigger
        )

        // Schedule notification
        do {
            try await notificationCenter.add(request)
            Logger.debug("NotificationManager: Scheduled test notification for in 5 seconds")
        } catch {
            Logger.error("NotificationManager: Failed to schedule test notification: \(error)")
        }
    }

    // MARK: - Helper Methods

    func enableNotifications() async -> Bool {
        if authorizationStatus == .notDetermined {
            showingSoftPrompt = true
            return false // Will be handled by soft prompt
        } else if authorizationStatus == .authorized {
            isNotificationEnabled = true
            return true
        } else {
            // Permission denied - user needs to go to Settings
            return false
        }
    }

    func disableNotifications() {
        isNotificationEnabled = false
        cancelScheduledNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Logger.debug("NotificationManager: User tapped notification")
        
        // Switch to the Memorize tab
        DispatchQueue.main.async {
            self.selectedTab = .memorize
            // Reset badge count on interaction
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even if app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
