## ADDED Requirements

### Requirement: Deferred Permission Request for Existing Users
The system SHALL NOT prompt existing users for notification permissions immediately upon app launch after an update.

#### Scenario: Existing user updates app
- **WHEN** an existing user who has not been prompted for notifications opens the app
- **THEN** the system SHALL defer the permission request until a meaningful interaction occurs (e.g., finishing a session or visiting Settings)

### Requirement: Soft Prompt for Notifications
The system SHALL present a contextual "soft prompt" explaining the benefit of reminders before requesting system-level notification permissions.

#### Scenario: User encounters first reminder opportunity
- **WHEN** the system is ready to request notification permissions
- **THEN** it SHALL first show an in-app message explaining how reminders help with memorization
- **AND** it SHALL only call the system requestAuthorization after the user expresses interest
