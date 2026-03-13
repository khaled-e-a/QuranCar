## 1. Core Audio Logic

- [x] 1.1 Add `playbackSpeed` property to `AudioManager` with `UserDefaults` persistence
- [x] 1.2 Implement `setPlaybackSpeed(_:)` in `AudioManager` to update the player's rate in real-time
- [x] 1.3 Ensure `AVPlayer.rate` is set correctly in `startPlayback()` and after item transitions in `playerItemDidFinish`
- [x] 1.4 Set `audioTimePitchAlgorithm` to `.timeDomain` on `AVPlayerItem` for better audio quality at variable speeds

## 2. iPhone UI Implementation

- [x] 2.1 Add a "Playback Speed" row to the "Settings" section in `SettingsView`
- [x] 2.2 Implement a picker or menu to select from 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x
- [x] 2.3 Connect the UI selection to `AudioManager.shared.setPlaybackSpeed()`

## 3. CarPlay Implementation

- [x] 3.1 Verify that `AudioManager` changes apply to CarPlay audio automatically
- [x] 3.2 (Optional) Add a playback speed toggle to the CarPlay `CPNowPlayingTemplate` if supported by the current template configuration

## 4. Verification & Testing

- [ ] 4.1 Verify audio plays at all supported speeds on iPhone
- [ ] 4.2 Verify speed setting persists after force-quitting and restarting the app
- [ ] 4.3 Verify CarPlay audio respects the speed setting selected on the iPhone
- [ ] 4.4 Confirm audio pitch remains natural across different speeds
