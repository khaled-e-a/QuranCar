# Proposal: fix-notification-system

**Title:** Robust Notification Logic and Refined Permission Flow

## 1. Problem Statement
The current notification system has three primary issues:
*   **Logic Flaw:** Notifications are only scheduled if the user *has already been* inactive for 3 days. Since usage is tracked on every launch, this condition is almost never met, and reminders are rarely scheduled.
*   **Verification Gap:** There is no way to verify that notifications are working correctly without waiting for 3 days.
*   **Aggressive Permissions:** Existing users are prompted for notification permissions immediately upon updating and opening the app, which is disruptive and lacks context.

## 2. Proposed Solution

### A. Proactive Scheduling Logic
Modify `NotificationManager` to adopt a "Proactive Scheduling" strategy:
*   Every time the app enters the background, schedule (or overwrite) a notification for **exactly 3 days in the future** at 2:00 PM.
*   Every time the app becomes active, cancel any pending notifications.

### B. Validation & Testing Tool
Add a developer/testing utility:
*   Add a "Test Notification" button in the **SettingsView**.
*   This button will schedule a notification for **5 seconds** from the current time, allowing for immediate verification of sound, content, and deep-linking.

### C. Refined Permission Flow
Improve the "Ask" experience:
*   **For New Users:** Keep the current flow (after onboarding).
*   **For Existing Users:** Instead of an immediate prompt on launch, wait until:
    *   The user completes their first memorization session.
    *   OR they visit the Settings page.
*   **Soft Prompt:** Introduce a "Soft Prompt" (an in-app banner or card) that explains *why* reminders are helpful before showing the system permission dialog.

## 3. Success Criteria
* [ ] A notification is successfully scheduled for 3 days in the future every time the app is backgrounded.
* [ ] The "Test Notification" button triggers a notification within 5 seconds.
* [ ] Existing users are not prompted for permissions until they have had a meaningful interaction with the app.
