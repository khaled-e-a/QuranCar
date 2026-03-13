# Spec: playback-speed-control

## Purpose
Define requirements for user-facing controls to adjust and persist audio playback speed across the iPhone app and CarPlay.

## Requirements

### Requirement: Variable Playback Speed
The system SHALL allow users with active Premium status to select from a predefined set of playback speeds: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, and 2.0x.

#### Scenario: Premium user selects a different speed
- **WHEN** a user with active Premium status selects "0.75x" in the playback speed settings
- **THEN** all subsequent audio playback SHALL occur at 0.75x speed
- **AND** the pitch of the audio SHALL remain natural (no chipmunk effect)

#### Scenario: Non-premium user attempts to select a different speed
- **WHEN** a user without active Premium status taps the playback speed selector
- **THEN** the system SHALL NOT allow the speed to be changed
- **AND** the system SHALL prompt the user to subscribe or join the Hadiya program

### Requirement: Persist Speed Preference
The system SHALL persist the selected playback speed across app launches.

#### Scenario: App restart
- **WHEN** the user sets playback speed to 1.25x and closes the app
- **THEN** upon restarting the app, the playback speed SHALL remain 1.25x

### Requirement: CarPlay Speed Integration
The system SHALL apply the selected playback speed to audio played through CarPlay.

#### Scenario: Playing in CarPlay
- **WHEN** the app is connected to CarPlay
- **THEN** the audio played on the car's speakers SHALL respect the speed setting currently active in the iPhone app
