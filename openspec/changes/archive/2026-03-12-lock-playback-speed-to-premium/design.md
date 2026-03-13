## Context

Playback speed control was recently implemented as a global feature. To align with the app's monetization strategy and support for the Hadiya program, this feature needs to be restricted to premium users. The app already has a unified premium check (`StoreManager.shared.isPremiumActive`) and a UI component for premium subscription (`PremiumSubscriptionCard`).

## Goals / Non-Goals

**Goals:**
- Restrict playback speed adjustment to premium users.
- Provide clear visual indicators (lock icon) for locked features.
- Leverage existing premium subscription flows (sheet/card).
- Maintain consistent enforcement on both iPhone and CarPlay.

**Non-Goals:**
- Removing the speed selector entirely for non-premium users (it should remain visible as an upsell).
- Changing the underlying audio engine logic.

## Decisions

### 1. UI Enforcement in `SettingsView`
- **Decision**: Wrap the Playback Speed `HStack` in a `Button` if the user is not premium.
- **Rationale**: This allows us to intercept the tap and show the premium sheet instead of the speed picker.
- **Visuals**: Add an `Image(systemName: "lock.fill")` when `!storeManager.isPremiumActive`.

### 2. UI Enforcement in `CarPlaySceneDelegate`
- **Decision**: Set `item.isEnabled = bookViewModel?.audioManager.isPremiumActive ?? false` for the playback speed list item.
- **Rationale**: CarPlay templates are more rigid. If disabled, the item cannot be tapped.
- **Alternative**: Keep it enabled but show an alert. Rejected because CarPlay alerts are intrusive and disabled states are the standard for locked features in CarPlay.

### 3. State Management
- **Decision**: Ensure that if a user's premium status expires, the `AudioManager` reverts the `playbackSpeed` to 1.0.
- **Rationale**: Prevents users from "locking in" a premium speed after their subscription ends.

## Risks / Trade-offs

- **[Risk] User Frustration** → Users might find it annoying that a previously free feature is now locked.
    - **Mitigation**: The Hadiya program provides a free path for those who cannot afford it, which is explicitly mentioned in the premium sheet.
- **[Risk] CarPlay Interactivity** → CarPlay users cannot see the "Subscribe" sheet.
    - **Mitigation**: The iPhone app will handle the subscription flow. The CarPlay item will simply be disabled, prompting the user to check their phone.
