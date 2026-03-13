## Context

Currently, the application plays Quranic audio at a fixed 1.0x speed. To improve the learning experience, we want to allow users to adjust the playback speed. The `AudioManager` class uses `AVPlayer`, which natively supports variable playback rates.

## Goals / Non-Goals

**Goals:**
- Provide a persistent playback speed setting (0.5x to 2.0x).
- Ensure real-time adjustment of speed during playback.
- Synchronize speed settings between the iPhone UI and CarPlay.
- Maintain natural audio pitch at all speeds.

**Non-Goals:**
- Allowing custom speed increments (we will use a predefined list).
- Implementing per-reciter speed settings.

## Decisions

### 1. Speed Storage and Management
- **Decision**: Add a `playbackSpeed` property to `AudioManager` (or a shared `Configuration` manager if one exists). Given `AudioManager` is an `ObservableObject`, it's a good candidate for the source of truth during playback.
- **Persistence**: Store the value in `UserDefaults` under the key `preferredPlaybackSpeed`.
- **Default**: 1.0x.

### 2. Audio Engine Integration
- **Decision**: Update `AudioManager.startPlayback()` and `playerItemDidFinish` to set the `player.rate` property.
- **Note**: `AVPlayer.rate` must be set *after* calling `play()` because `play()` resets the rate to 1.0 if not careful, OR we set it once and use `rate` to start playback (`player.rate = speed`).
- **Real-time update**: Implement a `setPlaybackSpeed(_:)` method in `AudioManager` that updates the `player.rate` immediately if audio is playing.

### 3. UI Implementation
- **iPhone**: Add a `Picker` or `Menu` in `SettingsView` (More tab).
- **CarPlay**: Add a "Speed" button to the `CPNowPlayingTemplate` or a separate `CPListTemplate` for settings if accessible. Since `CarPlaySceneDelegate` currently has limited interactivity, we'll start by ensuring the speed selected on the phone is respected in the car.

### 4. Audio Quality
- **Decision**: Use `AVPlayerItem.audioTimePitchAlgorithm = .timeDomain` or `.spectral` to ensure pitch correction. `AVPlayer` typically does this well by default for standard rates.

## Risks / Trade-offs

- **[Risk] AVPlayer Rate Reset** → `AVPlayer` sometimes resets `rate` to 0 or 1 when items change or errors occur.
    - **Mitigation**: Re-apply the speed whenever a new `AVPlayerItem` is loaded or playback is resumed.
- **[Risk] CarPlay Interactivity** → CarPlay templates are restrictive.
    - **Mitigation**: Focus on persistence so the user can set the speed once on their phone before driving.
