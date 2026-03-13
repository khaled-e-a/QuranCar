## Context

The current premium access logic in `StoreManager.swift` is strictly tied to StoreKit transactions. To implement the Hadiya (Gift) Program, we need to decouple the "Premium User" status from the "Paid Subscriber" status while maintaining data integrity and a seamless user experience.

## Goals / Non-Goals

**Goals:**
- Provide a unified way to check for premium status throughout the app.
- Securely persist the gift subscription period on the device.
- Add a respectful UI for requesting the gift.
- Ensure the gift can be renewed or updated after expiration.

**Non-Goals:**
- Backend verification of financial status (this is trust-based).
- Synchronization of Hadiya status across devices (it will be local to the device for now).
- Changing existing StoreKit 2 implementation.

## Decisions

### 1. Unified Premium Access Logic
- **Decision**: Introduce a computed property `isPremiumActive` in `StoreManager`.
- **Rationale**: Currently, views check `isSubscribed`. By using a unified property, we avoid updating every view when the definition of "Premium" changes.
- **Logic**: `isPremiumActive = isSubscribed || (hadiyaExpiryDate != nil && hadiyaExpiryDate! > Date())`.

### 2. Local Persistence for Hadiya
- **Decision**: Store Hadiya data in `UserDefaults`.
- **Rationale**: For a trust-based local-only program, `UserDefaults` is sufficient and simple to implement.
- **Keys**: 
    - `hadiyaGrantDate`: The timestamp when the gift was activated.
    - `hadiyaExpiryDate`: The timestamp (Grant Date + 365 days) when it expires.

### 3. Settings UI Integration
- **Decision**: Place the Hadiya entry point inside the `PremiumSubscriptionCard` or immediately below it in `SettingsView`.
- **Rationale**: This ensures users see the option when they are considering the standard subscription.
- **UX Flow**: 
    1. User taps "Hadiya Program".
    2. A sheet appears explaining the program's intent.
    3. User confirms ("I cannot afford the subscription").
    4. `StoreManager` updates local state and UI refreshes.

### 4. Handling Expiration
- **Decision**: `StoreManager` will check the expiry date on initialization and whenever the app foregrounds.
- **Rationale**: Ensures the premium features are locked immediately once the 12-month period passes.

## Risks / Trade-offs

- **[Risk] User Manipulation** → Users could manually change their system clock to extend the 12 months.
    - **Mitigation**: Acceptable for this specific app's mission. We prioritize accessibility over strict DRM.
- **[Risk] UserDefaults Clear** → If the user clears app data, they lose the Hadiya status.
    - **Mitigation**: They can simply re-apply via the UI.
