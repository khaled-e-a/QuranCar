## 1. Data Model & Storage

- [x] 1.1 Define constants for Hadiya `UserDefaults` keys (`hadiyaGrantDate`, `hadiyaExpiryDate`)
- [x] 1.2 Implement private storage helper methods in `StoreManager` to get/set Hadiya dates

## 2. StoreManager Core Refactor

- [x] 2.1 Add `@Published` property `hadiyaExpiryDate` to `StoreManager` and load it from `UserDefaults` on init
- [x] 2.2 Implement computed property `isPremiumActive` that combines `isSubscribed` and Hadiya status
- [x] 2.3 Implement `grantHadiyaSubscription()` method to set grant/expiry dates (Now + 365 days)
- [x] 2.4 Update `checkSubscriptionStatus()` or add a new method to verify Hadiya expiry on app foreground

## 3. UI Implementation

- [x] 3.1 Create `HadiyaConfirmationSheet` explaining the program and providing a confirmation button
- [x] 3.2 Add "Hadiya (Gift) Program" button to `PremiumSubscriptionCard` or `SettingsView`
- [x] 3.3 Connect the "Confirm" action in the sheet to `StoreManager.grantHadiyaSubscription()`
- [x] 3.4 Ensure UI correctly reflects unified premium status (showing "Premium Active" for Hadiya users)

## 4. Requirement Updates & Cleanup

- [x] 4.1 Search for all usages of `isSubscribed` in the codebase and migrate them to `isPremiumActive` (or similar unified check)
- [x] 4.2 Add explicit logging for Hadiya grant and expiration events

## 5. Verification & Testing

- [ ] 5.1 Verify that tapping "Hadiya Program" and confirming grants premium access immediately
- [ ] 5.2 Verify that premium features (like restricted reciters) are unlocked for Hadiya users
- [ ] 5.3 Test expiration logic by manually setting an old expiry date in `UserDefaults` and backgrounding/foregrounding the app
