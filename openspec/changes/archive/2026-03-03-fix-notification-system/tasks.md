## 1. Notification Manager Refactor

- [x] 1.1 Update `scheduleNotificationIfNeeded` to proactively schedule for (Now + 3 Days) at 2:00 PM
- [x] 1.2 Implement `scheduleTestNotification` to trigger a reminder in 5 seconds
- [x] 1.3 Ensure `cancelScheduledNotifications` and `trackAppUsage` are robust and used correctly across app lifecycle

## 2. Refined Permission Flow

- [x] 2.1 Update `ContentView` to remove the immediate `requestAuthorization` call for existing users
- [x] 2.2 Implement a "Soft Prompt" UI (e.g., a sheet or custom alert) in `SettingsView` and after meaningful interactions
- [x] 2.3 Update `enableNotifications` in `NotificationManager` to support the new soft prompt flow

## 3. Settings UI Improvements

- [x] 3.1 Add "Test Notification" button to `SettingsView`
- [x] 3.2 Add a description of the reminder benefits in `SettingsView` to act as a permanent soft prompt
- [x] 3.3 Verify that the "Open Settings" deep-link works correctly when permission is denied

## 4. Verification & Testing

- [x] 4.1 Verify the proactive scheduling logic by backgrounding the app and checking logs
- [x] 4.2 Use the "Test Notification" button to verify delivery and content
- [x] 4.3 Verify that existing users are not prompted for notifications on first launch after update
