## Context

The current notification system in `NotificationManager.swift` tracks app usage correctly but fails to schedule reminders effectively. It only attempts to schedule a notification if the user *is already* inactive for 3 days, which is logicially incorrect for a retention reminder. Additionally, permissions are requested too aggressively for existing users, and there is no way to verify notification delivery without waiting 3 days.

## Goals / Non-Goals

**Goals:**
- Fix the logic to proactively schedule a reminder for 3 days in the future every time the app is backgrounded.
- Implement a "soft prompt" for notification permissions to improve user opt-in rates.
- Defer permission requests for existing users until a meaningful interaction occurs.
- Provide a developer utility in Settings to trigger an immediate test notification.

**Non-Goals:**
- Implementing a remote push notification system (keeping it local-only).
- Changing the notification content or time of day (2:00 PM).
- Adding complex analytics for notification open rates.

## Decisions

### 1. Proactive Scheduling in `NotificationManager`
- **Decision**: Always schedule a notification for `(Now + 3 days) at 2 PM` when `applicationDidEnterBackground` is called.
- **Rationale**: This ensures that if the user doesn't return, the reminder is already "in the chamber." The existing logic of canceling all pending notifications on app launch ensures no duplicate or stale reminders fire while the user is active.
- **Alternatives**: Scheduling only once every 3 days. Rejected because it's more complex to track and less reliable than just overwriting the single scheduled reminder.

### 2. "Soft Prompt" UI Pattern
- **Decision**: Use an in-app `Sheet` or `Overlay` in `MainView` or `SettingsView` that explains the benefits of reminders before calling the system `requestAuthorization`.
- **Rationale**: Standard mobile UX practice shows that users are more likely to grant permission if they understand the value first.
- **Alternatives**: Direct system prompt. Rejected as it's too aggressive and "one-shot" (if denied, it's hard to recover).

### 3. Developer Test Tool
- **Decision**: Add a button in `SettingsView` (visible to all for now, as it's a small app) called "Test Notification" that triggers a 5-second delay reminder.
- **Rationale**: Critical for QA and for the user to see what the reminder looks like.
- **Alternatives**: Hidden debug menu. Rejected for simplicity; having it visible in Settings is fine for a utility-focused app.

## Risks / Trade-offs

- **[Risk]** Over-scheduling/Spamming → **Mitigation**: The `notificationIdentifier` is constant (`qurancar_inactivity_reminder`), so `UNUserNotificationCenter` automatically replaces the old one with the new one.
- **[Risk]** Existing users never seeing the prompt → **Mitigation**: Trigger the "soft prompt" when the user completes a memorization segment (transition between chunks).
