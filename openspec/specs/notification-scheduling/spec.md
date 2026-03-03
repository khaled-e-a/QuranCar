# Spec: notification-scheduling

## Purpose
Define requirements for scheduling inactivity reminders when the app enters the background and canceling them when the app becomes active.

## Requirements

### Requirement: Proactive Inactivity Reminders
The system SHALL schedule a local notification to be delivered exactly 3 days in the future when the app enters the background.

#### Scenario: User backgrounds the app
- **WHEN** the app transition to the background state
- **THEN** the system SHALL schedule a reminder for 3 days from the current time at 2:00 PM
- **AND** any previously scheduled inactivity reminders SHALL be replaced

### Requirement: Reminder Cancellation on Activity
The system SHALL cancel all pending inactivity reminders when the app enters the foreground.

#### Scenario: User opens the app
- **WHEN** the app transition to the foreground or active state
- **THEN** the system SHALL remove all pending notification requests with the inactivity reminder identifier
