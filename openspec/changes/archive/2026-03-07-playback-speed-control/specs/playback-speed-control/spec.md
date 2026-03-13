## ADDED Requirements

### Requirement: Variable Playback Speed
The system SHALL allow the user to select from a predefined set of playback speeds: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, and 2.0x.

#### Scenario: User selects a different speed
- **WHEN** the user selects "0.75x" in the playback speed settings
- **THEN** all subsequent audio playback SHALL occur at 0.75x speed
- **AND** the pitch of the audio SHALL remain natural (no chipmunk effect)

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
