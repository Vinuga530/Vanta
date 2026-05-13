# Implement Strict Mode, Smart Unlock, Grayscale, Overlay, and Session-End Prompt

## Summary
- Implement the unfinished protection features instead of removing them.
- Treat `Strict Mode` as an in-app lock on blocker controls during active blocked periods for the blocked social apps list.
- Treat `Smart Unlock` as a 5-minute pause of all blocking rules, then automatically resume.
- Add Home-screen session controls for `Grayscale` and `Overlay` that are available only while Focus Mode is active.
- Make those Home toggles session-only overrides; they do not rewrite the saved Settings defaults.
- Make the active Focus timer authoritative: when it reaches `00:00`, prompt the user to extend the session or end it; if there is no response within the timeout, automatically end Focus Mode.
- Implement `Grayscale` as an accessibility-overlay approximation, not true OS-level grayscale, because the current permission model does not support a global system color transform for a normal app.
- Keep `flutter analyze` and `flutter test` green throughout.

## Final Product Behavior
1. `Strict Mode`
- Applies only when all of these are true: `Focus Mode` is on, current time is inside a blocked day/time window, current app or targeted content falls under active blocking rules, and `Strict Mode` is enabled.
- While active, the user cannot turn off Focus Mode and cannot change blocker-affecting settings unless they first start `Smart Unlock`.
- “Blocker-affecting settings” means: blocked apps list, blocked keywords, view blockers, schedule times, repeat days, `Strict Mode`, `Smart Unlock`, and warning-screen configuration.
- Appearance settings and non-blocking informational UI remain editable.
- If the user tries to change locked controls, show a modal explaining that `Strict Mode` is active and offering `Start Smart Unlock` if Smart Unlock is enabled.

2. `Smart Unlock`
- If enabled in Settings, blocked-app attempts and locked-settings dialogs expose `Unlock for 5 minutes`.
- Starting Smart Unlock pauses all blocking for 5 minutes: app blocking, keyword blocking, Shorts/Reels/Comments/Explore blockers, and strict-mode editing locks.
- Focus Mode itself remains on during Smart Unlock.
- At the end of 5 minutes, all blocking automatically resumes without requiring user action.
- If Smart Unlock is already active, a second unlock action does not extend it; the UI should show the remaining time instead.
- The Smart Unlock countdown survives app backgrounding and app restarts during the same focus session.

3. `Grayscale`
- Saved Settings value remains the default for new focus sessions.
- During an active focus session, the Home screen shows a live `Grayscale` toggle inside the Focus card area.
- That Home toggle affects all apps while Focus Mode is active, not just blocked apps.
- The Home toggle is session-only: it resets when Focus Mode ends, and the next session starts from the saved Settings default again.
- Because true device-wide grayscale is not feasible with the current permission set, implement this as a full-screen neutral monochrome accessibility overlay that visually desaturates the experience as much as possible without intercepting touches.
- Do not show the grayscale overlay on the Vanta app itself, on the warning screen, or on the session-end extension prompt.

4. `Screen Time Overlay`
- Saved Settings value remains the default for new focus sessions.
- During an active focus session, the Home screen shows a live `Overlay` toggle inside the Focus card area.
- That Home toggle affects all apps while Focus Mode is active.
- The overlay displays the remaining Focus countdown, not elapsed time and not daily screen time.
- The overlay is session-only and resets when Focus Mode ends.
- The overlay should be hidden on the Vanta app itself, on the launcher/home screen, on the warning screen, and on the session-end extension prompt.

5. Focus Timer Session Lifecycle
- When Focus Mode is turned on, create an active focus session with:
  - `focusStartedAt`
  - `focusEndsAt`
  - session copies of `grayscale` and `overlay` seeded from saved Settings defaults
- When the timer reaches `00:00`, show a session-end prompt asking whether to extend or end the session.
- The session-end prompt offers exactly two actions: `Extend 10 minutes` and `End Focus`.
- If the user does not respond within 30 seconds, automatically end Focus Mode.
- Ending Focus Mode clears:
  - active focus session timestamps
  - Smart Unlock expiration
  - session overlay/grayscale toggles
  - any overlay views
- Extending the session adds 10 minutes to `focusEndsAt` and resumes the overlay countdown immediately.

## Important Public API / Interface / Type Changes
### Dart service and state changes
- Add session-state support to `PreferencesService` for persisted runtime state:
  - `setFocusSessionStartMillis` / `getFocusSessionStartMillis`
  - `setFocusSessionEndMillis` / `getFocusSessionEndMillis`
  - `setSessionGrayscaleEnabled` / `getSessionGrayscaleEnabled`
  - `setSessionOverlayEnabled` / `getSessionOverlayEnabled`
  - `setSmartUnlockEndMillis` / `getSmartUnlockEndMillis`
  - `clearFocusSessionState`
  - `isSmartUnlockActive`
  - `getSmartUnlockRemainingSeconds`
  - `isFocusSessionActive`
- Keep existing saved defaults:
  - `getGrayscaleEnabled`
  - `getShowTimeOverlay`
  - `getStrictMode`
  - `getSmartUnlock`
- Do not replace saved defaults with session overrides.

- Extend `BlockService.updateBlockingConfig` payload to include:
  - `focusSessionStartMillis`
  - `focusSessionEndMillis`
  - `sessionGrayscaleEnabled`
  - `sessionOverlayEnabled`
  - `smartUnlockEndMillis`
  - `strictModeEnabled`
  - `smartUnlockEnabled`

### Native Android channel additions
- Add method-channel getters/actions in `MainActivity.kt`:
  - `startSmartUnlock`
  - `extendFocusSession`
  - `endFocusSession`
  - `getProtectionRuntimeState`
- `getProtectionRuntimeState` returns current native-visible state for diagnostics and UI hydration if needed:
  - `focusSessionEndMillis`
  - `smartUnlockEndMillis`
  - `overlayVisible`
  - `grayscaleVisible`

### New Android components
- Add a new `FocusSessionTimeoutActivity.kt` for the end-of-session prompt.
- Register it in `AndroidManifest.xml` as non-exported, fullscreen, and excluded from recents.
- Reuse the existing warning-style visual language for consistency.

## Implementation Plan
### 1. Persisted session model
- Move Focus timer ownership out of the Home widget-only `Timer` state and into persisted session timestamps.
- Home can still use a local ticker for rendering, but the source of truth must be `focusSessionEndMillis`.
- When Focus Mode turns on:
  - set `focusActive = true`
  - set `focusSessionStartMillis = now`
  - set `focusSessionEndMillis = now + focusTimerMinutes`
  - set `sessionGrayscaleEnabled = savedGrayscaleDefault`
  - set `sessionOverlayEnabled = savedOverlayDefault`
  - clear any old `smartUnlockEndMillis`
  - push full config to native
- When Focus Mode turns off:
  - clear the full focus session state
  - push `active = false` to native
  - remove all overlays natively

### 2. Home screen changes
- Update `HomeScreen` to derive countdown from `focusSessionEndMillis` instead of an internal one-shot session counter.
- Add two quick toggles inside the Focus hero card, visible only while Focus Mode is active:
  - `Grayscale`
  - `Overlay`
- Those toggles update the session-only values and immediately call `BlockService.restartBlocking()` or a lighter-weight native sync method.
- If the session expires while Vanta is foregrounded, route to the same extend/end prompt state used by native timeout handling.
- If `Strict Mode` is active and the user tries to turn Focus Mode off, intercept that action and show the strict-mode modal instead of toggling off directly.

### 3. Settings and blocker locking
- In `SettingsScreen` and `BlockersScreen`, compute `isStrictLockActive` from:
  - `focusActive`
  - current blocked schedule active
  - `Strict Mode` enabled
  - `Smart Unlock` not active
- Lock the following UI during `isStrictLockActive`:
  - App add/remove
  - Keyword add/remove
  - View-blocker toggles
  - Schedule time changes
  - Repeat-day changes
  - `Strict Mode` switch
  - `Smart Unlock` switch
  - warning message editor
- Locked controls should remain visible but non-interactive, and tapping them should open the strict-mode explanation dialog.
- Keep `Appearance`, session timer defaults, and permission screens available.

### 4. Warning screen and Smart Unlock entry
- Update `WarningActivity` so that when a blocked app is opened and Smart Unlock is enabled but not currently active, the screen includes:
  - `Unlock for 5 minutes`
  - `Back`
- `Unlock for 5 minutes` should:
  - persist `smartUnlockEndMillis = now + 5 minutes`
  - push updated native config
  - dismiss the warning screen
- If Smart Unlock is already active, show the remaining unlock time instead of another button.

### 5. Native blocking rules
- Extend `VantaAccessibilityService` companion state with:
  - `focusSessionEndMillis`
  - `smartUnlockEndMillis`
  - `sessionGrayscaleEnabled`
  - `sessionOverlayEnabled`
  - `strictModeEnabled`
  - `smartUnlockEnabled`
- Add helper methods:
  - `isFocusSessionExpired()`
  - `isSmartUnlockActive()`
  - `getRemainingFocusSeconds()`
  - `getRemainingSmartUnlockSeconds()`
- Change `shouldBlock(pkg)` to short-circuit `false` while Smart Unlock is active.
- Change keyword and view-blocking handlers to short-circuit while Smart Unlock is active.
- When focus session expires:
  - launch `FocusSessionTimeoutActivity`
  - if no answer in 30 seconds, end Focus Mode natively and clear session state
- `FocusSessionTimeoutActivity` actions:
  - `Extend 10 minutes` updates `focusSessionEndMillis`
  - `End Focus` clears session state and disables active blocking
- If Vanta is not foregrounded, native timeout handling still works because the accessibility service owns the expiry check.

### 6. Overlay implementation
- Rework the existing `showTimeOverlayView()` into a general session overlay manager.
- Display the overlay only when:
  - Focus Mode is active
  - session overlay toggle is enabled
  - current foreground package is not Vanta
  - current foreground package is not the launcher/home screen
  - current UI is not `WarningActivity`
  - current UI is not `FocusSessionTimeoutActivity`
- Overlay text format:
  - `Focus 24:59`
  - always countdown, minutes and seconds
- Update once per second based on `focusSessionEndMillis`, not local elapsed time.
- Remove overlay immediately on:
  - Focus Mode off
  - overlay toggle off
  - launcher/home screen
  - warning screen
  - extension prompt
  - session expiration

### 7. Grayscale approximation implementation
- Add a second non-interactive full-screen accessibility overlay view for grayscale approximation.
- Use a fullscreen neutral gray scrim with tuned alpha that reduces color intensity without blocking input.
- Show it only when:
  - Focus Mode is active
  - session grayscale toggle is enabled
  - current foreground package is not Vanta
  - current foreground package is not launcher/home
  - current UI is not `WarningActivity`
  - current UI is not `FocusSessionTimeoutActivity`
- Manage it separately from the timer overlay so either can be enabled independently.
- Document in code comments that this is an approximation due to Android permission limitations.

### 8. Session-end prompt behavior
- `FocusSessionTimeoutActivity` should:
  - be visually aligned with `WarningActivity`
  - show “Focus session complete”
  - show current choices: `Extend 10 minutes` and `End Focus`
  - auto-end after 30 seconds with visible countdown text
- If the user extends:
  - persist new `focusSessionEndMillis`
  - restart overlay countdowns
  - return to previous app
- If the user ends or timeout occurs:
  - clear focus session state
  - set `focusActive = false`
  - clear Smart Unlock
  - remove overlays
  - stop native blocking

## File-Level Change List
- `lib/services/preferences_service.dart`
  - add persisted session runtime keys and helpers
  - keep saved defaults separate from session overrides
- `lib/services/block_service.dart`
  - extend payload and add Smart Unlock / session actions
- `lib/screens/home_screen.dart`
  - migrate timer to persisted session timestamps
  - add session-only quick toggles
  - add strict-mode interception logic
- `lib/screens/settings_screen.dart`
  - lock blocker-affecting controls during strict mode
  - keep saved defaults editable when not locked
- `lib/screens/blockers_screen.dart`
  - lock add/remove/toggle actions during strict mode
- `android/app/src/main/kotlin/.../MainActivity.kt`
  - add new channel methods for runtime protection control/state
- `android/app/src/main/kotlin/.../VantaAccessibilityService.kt`
  - add session-state awareness, Smart Unlock bypass, overlay managers, and timer expiry handling
- `android/app/src/main/kotlin/.../WarningActivity.kt`
  - add Smart Unlock CTA and remaining-time state
- `android/app/src/main/kotlin/.../FocusSessionTimeoutActivity.kt`
  - new file
- `android/app/src/main/AndroidManifest.xml`
  - register timeout activity
- `README.md`
  - update feature descriptions so they match actual behavior and note grayscale is a focus visual filter rather than true OS grayscale

## Test Cases and Scenarios
### Dart / widget tests
- Focus Mode on seeds a session start, session end, and session overlay/grayscale defaults.
- Turning Focus Mode off clears all session-only state.
- Home quick toggles change only session values, not saved settings defaults.
- Strict mode blocks Focus toggle-off while block window is active.
- Strict mode blocks blocker edits while block window is active.
- Strict-mode lock is bypassed while Smart Unlock is active.
- Smart Unlock remaining-time computation is correct across restart/resume.
- Session countdown derives from persisted end time, not local widget init time.
- Focus-session expiry triggers the extension flow state instead of silently hitting zero.

### Android/native behavior tests or manual verification
- Blocked app opens warning screen when block window is active and Smart Unlock is inactive.
- `Unlock for 5 minutes` suspends app blocking, keyword blocking, and view blocking for exactly 5 minutes.
- Blocking resumes automatically after 5 minutes without reopening Vanta.
- Overlay appears on third-party apps during active focus session when enabled.
- Overlay hides on Vanta, launcher, warning screen, and extension prompt.
- Grayscale overlay appears on third-party apps during active focus session when enabled.
- Grayscale overlay hides in the excluded screens/packages.
- When focus timer expires in another app, the timeout prompt appears.
- If the user taps `Extend 10 minutes`, the countdown and overlays continue immediately.
- If the user ignores the prompt for 30 seconds, Focus Mode ends automatically and overlays disappear.
- Restarting the app mid-session restores remaining countdown and Smart Unlock state correctly.

### Regression checks
- Existing app blocking still respects blocked days and blocked hours.
- Device-admin and accessibility required-permission gating still works.
- Analyzer remains clean.
- Widget test suite remains passing.

## Assumptions and Defaults
- `Smart Unlock` duration is fixed at 5 minutes for this implementation.
- Session-end extension duration is fixed at 10 minutes for this implementation.
- Session-end auto-timeout is fixed at 30 seconds for this implementation.
- `Grayscale` is implemented as an accessibility-overlay approximation, not true system grayscale.
- Home-screen `Grayscale` and `Overlay` toggles are session-only overrides and reset when Focus Mode ends.
- Saved Settings values for `Grayscale` and `Overlay` are treated as defaults for future sessions.
- The focus countdown becomes the authoritative session clock; it is no longer only decorative widget state.
- Strict-mode locking is enforced inside Vanta’s UI and native blocking flow; it does not attempt impossible system-level prevention outside the app’s permission model.
