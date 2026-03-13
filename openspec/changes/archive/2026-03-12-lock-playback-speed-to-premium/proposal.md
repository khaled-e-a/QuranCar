## Why

To encourage users to support the project via subscriptions or the Hadiya program, playback speed adjustment is being designated as a premium feature. This follows the established pattern of offering core functionality for free while providing advanced features (like all reciters and ad-free experience) to premium users.

## What Changes

- **Locked Speed Control**: The playback speed selector in the Settings menu will be visible but disabled for non-premium users.
- **Visual Feedback**: A lock icon will be added next to the speed setting for non-premium users.
- **Upsell Trigger**: Tapping the locked speed control will prompt the user to subscribe or join the Hadiya program.
- **CarPlay Enforcement**: The CarPlay interface will also reflect the locked status of the playback speed feature.

## Capabilities

### Modified Capabilities
- `playback-speed-control`: Update requirements to restrict access to users with active premium status.
- `premium-access`: Add playback speed control to the list of premium-only features.

## Impact

- **`SettingsView.swift`**: Update UI to show lock icon and handle tap events for non-premium users.
- **`CarPlaySceneDelegate.swift`**: Update template creation to disable speed selection if not premium.
- **`AudioManager.swift`**: (Maybe) Ensure speed is reset to 1.0 if premium status expires.
