//
//  NotificationManager.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
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

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isNotificationEnabled: Bool {
        didSet {
            defaults.set(isNotificationEnabled, forKey: UserDefaultsKeys.notificationsEnabled)
            if !isNotificationEnabled {
                cancelScheduledNotifications()
            }
        }
    }

    private init() {
        // Load saved preference
        self.isNotificationEnabled = defaults.bool(forKey: UserDefaultsKeys.notificationsEnabled)

        // Check current authorization status
        Task {
            await checkAuthorizationStatus()
        }
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
        Logger.debug("NotificationManager: Tracked app usage at \(Date())")

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
            Logger.debug("NotificationManager: Notifications are disabled, skipping scheduling")
            return
        }

        // Check authorization status
        Task { @MainActor in
            await checkAuthorizationStatus()

            guard authorizationStatus == .authorized else {
                Logger.debug("NotificationManager: Notifications not authorized, skipping scheduling")
                return
            }

            // Check if user has been inactive for the threshold period
            guard let timeSinceLastUsage = timeSinceLastUsage(),
                  timeSinceLastUsage >= inactivityThreshold else {
                Logger.debug("NotificationManager: User has been active recently, no notification needed")
                return
            }

            // Schedule notification for tomorrow at 2 PM
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

        // Schedule for next 2 PM (today if before 2 PM, tomorrow if after 2 PM)
        let calendar = Calendar.current
        let now = Date()
        var targetComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        targetComponents.hour = notificationHour
        targetComponents.minute = notificationMinute

        guard var triggerDate = calendar.date(from: targetComponents) else {
            Logger.error("NotificationManager: Failed to create trigger date")
            return
        }

        // If 2 PM today has already passed, schedule for tomorrow
        if triggerDate <= now {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: triggerDate) else {
                Logger.error("NotificationManager: Failed to calculate tomorrow's date")
                return
            }
            triggerDate = tomorrow
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
            Logger.debug("NotificationManager: Scheduled notification for \(triggerDate)")
        } catch {
            Logger.error("NotificationManager: Failed to schedule notification: \(error)")
        }
    }

    func cancelScheduledNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
        Logger.debug("NotificationManager: Cancelled scheduled notifications")
    }

    // MARK: - Helper Methods

    func enableNotifications() async -> Bool {
        if authorizationStatus == .notDetermined {
            let granted = await requestAuthorization()
            if granted {
                isNotificationEnabled = true
                return true
            }
            return false
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
