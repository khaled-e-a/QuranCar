## ADDED Requirements

### Requirement: Instant Test Notification
The system SHALL provide a way for developers/testers to trigger an immediate notification for verification purposes.

#### Scenario: Trigger test notification
- **WHEN** the user taps the "Test Notification" button in Settings
- **THEN** the system SHALL schedule a local notification to fire in 5 seconds
- **AND** the notification content SHALL match the standard inactivity reminder
