## 1. iPhone UI Updates

- [x] 1.1 Update `SettingsView` to check `storeManager.isPremiumActive` for playback speed control
- [x] 1.2 Display a lock icon next to "Playback Speed" for non-premium users
- [x] 1.3 Trigger the premium subscription sheet when a non-premium user taps the playback speed row

## 2. CarPlay Updates

- [x] 2.1 Update `CarPlaySceneDelegate` to disable the playback speed item if `isPremiumActive` is false
- [x] 2.2 Ensure the checkmark and speed selection logic respects the premium status in CarPlay

## 3. Core Logic

- [x] 3.1 Update `AudioManager` to reset speed to 1.0x if premium status is lost (optional but recommended)
- [x] 3.2 Add `isPremiumActive` computed property to `AudioManager` or ensure it has access to `StoreManager`

## 4. Verification

- [ ] 4.1 Verify playback speed is locked and shows lock icon for non-premium users on iPhone
- [ ] 4.2 Verify tapping locked speed opens the premium/hadiya sheet
- [ ] 4.3 Verify playback speed is enabled and functional for premium users
- [ ] 4.4 Verify CarPlay playback speed item is disabled for non-premium users
