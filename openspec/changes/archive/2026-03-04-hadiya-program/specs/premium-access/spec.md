## ADDED Requirements

### Requirement: Unified Premium Status
The system SHALL determine premium access by checking both active StoreKit subscriptions and active Hadiya grants.

#### Scenario: User with active Hadiya grant
- **WHEN** the system checks for premium status
- **AND** the user has a valid Hadiya grant that has not expired
- **THEN** the system SHALL treat the user as a Premium user

#### Scenario: User with active StoreKit subscription
- **WHEN** the system checks for premium status
- **AND** the user has an active paid subscription
- **THEN** the system SHALL treat the user as a Premium user

### Requirement: Premium Feature Unlock
The system SHALL unlock all premium features (e.g., all reciters, ad-free experience) for users with Premium status.

#### Scenario: Accessing premium reciter
- **WHEN** a user with Premium status selects a premium reciter
- **THEN** the system SHALL allow audio playback for that reciter
