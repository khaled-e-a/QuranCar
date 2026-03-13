# Spec: hadiya-program

## Purpose
The Hadiya (Gift) Program ensures that financial constraints do not prevent users from accessing premium features of QuranCar. It provides a trust-based mechanism for users in need to receive a free 12-month premium period.

## Requirements

### Requirement: Hadiya Request Flow
The system SHALL provide a respectful and accessible way for users to request a gift subscription if they cannot afford the premium subscription.

#### Scenario: User requests Hadiya
- **WHEN** the user selects the "Hadiya Program" option in Settings
- **AND** confirms they cannot afford the subscription
- **THEN** the system SHALL grant 12 months of premium access immediately

### Requirement: 12-Month Hadiya Grant
The system SHALL grant premium access for a period of exactly 12 months from the date of the request.

#### Scenario: Grant period calculation
- **WHEN** a Hadiya request is processed
- **THEN** the system SHALL calculate an expiry date exactly 365 days from the current date
- **AND** store this date securely on the device

### Requirement: Hadiya Expiry Notification
The system SHALL notify the user when their Hadiya subscription is about to expire or has expired.

#### Scenario: Hadiya expiration
- **WHEN** the current date passes the stored Hadiya expiry date
- **THEN** the system SHALL revert the user's status to non-premium
- **AND** allow them to re-apply if the program is still active
