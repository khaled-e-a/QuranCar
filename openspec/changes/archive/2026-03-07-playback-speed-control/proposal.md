## Why

Users have varying levels of familiarity with Quranic verses and different learning paces. Providing playback speed control allows users to slow down audio (e.g., 0.75x) for precise memorization and tajweed practice, or speed it up (e.g., 1.25x, 1.5x) for efficient review of already memorized sections.

## What Changes

- **Speed Selector UI**: Add a new configuration section in the "More" (Settings) menu to select playback speed (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
- **Persistent Speed Setting**: Save the selected playback speed in `UserDefaults` so it persists across sessions.
- **Audio Engine Update**: Update the `AudioManager` to apply the selected speed to the `AVPlayer` or `AVAudioPlayer` instance.
- **CarPlay Integration**: Ensure the selected playback speed is respected during CarPlay sessions and potentially add a speed toggle to the CarPlay "Now Playing" or settings template.

## Capabilities

### New Capabilities
- `playback-speed-control`: The ability to adjust and persist audio playback speed across the application and CarPlay.

### Modified Capabilities
- `audio-playback`: Requirements for audio playback will now include variable speed support.

## Impact

- **`AudioManager.swift`**: Needs to handle the `rate` property of the audio player.
- **`SettingsView.swift`**: New UI elements for speed selection.
- **`CarPlayConnectionManager.swift` / `CarPlaySceneDelegate.swift`**: Updating the CarPlay interface to reflect or allow changing the speed.
- **`UserDefaults`**: New key for storing the preferred speed.
