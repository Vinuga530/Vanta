# Vanta

A focus and app blocker for Android built with Flutter. Vanta helps you take back control of your screen time by blocking distracting apps on a schedule — so you stay focused during the day and unwind on your own terms.

---

## Features

- **Focus Mode** — block distracting apps with a single toggle
- **Scheduled Blocking** — set exact hours when apps are restricted
- **Per-App Control** — configure individual rules for each app
- **Repeat Days** — choose which days of the week blocking is active
- **Strict Mode** — prevent disabling the blocker during active hours
- **Smart Unlock** — allow a 5-minute emergency window when needed
- **Usage Stats** — see how much time you're spending on blocked apps
- **Material You Design** — clean, native Android look and feel

---

## Built With

- [Flutter](https://flutter.dev) — cross-platform UI framework
- [Dart](https://dart.dev) — programming language
- Kotlin — Android native services (accessibility, blocking, widget)
- Android Accessibility Service — core blocking mechanism
- SharedPreferences — local settings persistence

---

## Project Structure

```
lib/
  main.dart                  # App entry point
  screens/
    home_screen.dart         # Main dashboard
    blockers_screen.dart     # Blocked apps list
    app_picker_screen.dart   # Add apps to block list
    schedule_screen.dart     # Time and day scheduling
    stats_screen.dart        # Usage statistics
    settings_screen.dart     # App settings
  services/
    block_service.dart       # Core blocking logic
    usage_service.dart       # App usage tracking
    preferences_service.dart # Settings persistence
  widgets/
    ios_components.dart      # Shared UI components
android/
  app/src/main/kotlin/
    BlockingService.kt             # Background blocking service
    VantaAccessibilityService.kt   # Accessibility service
    VantaDeviceAdminReceiver.kt    # Device admin
    VantaWidgetProvider.kt         # Home screen widget
    WarningActivity.kt             # Block warning screen
```

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Android SDK 35+
- Java 17
- Android device with Developer Options enabled

### Run the app

```bash
git clone https://github.com/Vinuga530/Vanta.git
cd Vanta
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
```

---

## Permissions Required

| Permission | Reason |
|-----------|--------|
| Usage Access | Detect which app is in the foreground |
| Accessibility Service | Redirect away from blocked apps |
| Device Admin | Enforce strict mode |
| Foreground Service | Keep blocker running in background |

---

## Status

🚧 **Active development** — core UI and Android services complete, background blocking in progress.

---

## Author

**Vinuga** — building toward a cybersecurity career, one project at a time.

---

## License

This project is for personal and educational use.
