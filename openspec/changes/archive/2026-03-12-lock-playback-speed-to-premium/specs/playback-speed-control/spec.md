## MODIFIED Requirements

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
