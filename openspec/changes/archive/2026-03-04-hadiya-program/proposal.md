## Why

To ensure that the Quran remains accessible to everyone regardless of their financial situation. The Hadiya (Gift) Program allows users who cannot afford the premium subscription to receive 12 months of access for free, embodying the spirit of generosity and removing financial barriers to memorization.

## What Changes

- **Hadiya Option**: Add a respectful entry point for the Hadiya program in the subscription section of the Settings view.
- **Gift Grant Logic**: Implement a mechanism to grant 12 months of premium access upon user request.
- **Unified Subscription State**: Update the application's "isSubscribed" check to account for both active StoreKit subscriptions and active Hadiya grants.
- **Persistence**: Store the Hadiya grant details (start date, expiry date) securely on the device.

## Capabilities

### New Capabilities
- `hadiya-program`: The flow and logic for requesting, granting, and tracking free 12-month premium access.

### Modified Capabilities
- `premium-access`: Update the requirement for "Premium Access" to include users with an active Hadiya grant. (Note: This capability spec will be created or modified to reflect that paid status is no longer the ONLY way to get premium features).

## Impact

- **`StoreManager.swift`**: Needs to expose a unified `isPremiumActive` property that combines IAP status and Hadiya status.
- **`SettingsView.swift`**: UI update to present the Hadiya program option when the user is not already subscribed.
- **Data Persistence**: New keys in `UserDefaults` or a similar store to track the gift period.
