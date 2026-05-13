import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'preferences_service.dart';

/// Service that manages the native Android blocking service.
class BlockService {
  static const _channel = MethodChannel('com.focusblocker/blocking');
  static const smartUnlockDurationMinutes = 5;
  static const focusExtensionMinutes = 10;

  /// Map of app display names to their Android package names.
  static const Map<String, String> appPackageNames = {
    'Instagram': 'com.instagram.android',
    'TikTok': 'com.zhiliaoapp.musically',
    'YouTube': 'com.google.android.youtube',
  };
  static const List<String> defaultBlockedPackages = [
    'com.instagram.android',
    'com.zhiliaoapp.musically',
  ];

  /// Seed blocked apps once so Flutter UI and native enforcement share the same list.
  static Future<void> initializeDefaults() async {
    if (PreferencesService.getBlockedPackagesInitialized()) {
      return;
    }

    final migratedPackages = <String>[];
    for (final entry in appPackageNames.entries) {
      final defaultBlocked = entry.key != 'YouTube';
      if (PreferencesService.getAppBlocked(entry.key, defaultBlocked)) {
        migratedPackages.add(entry.value);
      }
    }

    await PreferencesService.setBlockedPackages(
      migratedPackages.isEmpty ? defaultBlockedPackages : migratedPackages,
    );
    await PreferencesService.setBlockedPackagesInitialized(true);
  }

  // ─── Permission Helpers ──────────────────────────────────────────────────────

  /// Check if the app has Accessibility Service permission.
  static Future<bool> hasAccessibilityPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        'hasAccessibilityPermission',
      );
      return result;
    } on Exception {
      return false;
    }
  }

  /// Open the Android Accessibility settings page.
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on Exception catch (e) {
      debugPrint('Failed to open Accessibility settings: $e');
    }
  }

  /// Check if usage stats permission is granted.
  static Future<bool> hasUsagePermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasUsagePermission');
      return result;
    } on Exception {
      return false;
    }
  }

  /// Open usage access settings.
  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } on Exception catch (e) {
      debugPrint('Failed to open Usage settings: $e');
    }
  }

  static Future<bool> hasDeviceAdminPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        'hasDeviceAdminPermission',
      );
      return result;
    } on Exception {
      return false;
    }
  }

  static Future<void> requestDeviceAdminPermission() async {
    try {
      await _channel.invokeMethod('requestDeviceAdminPermission');
    } on Exception catch (e) {
      debugPrint('Failed to request device admin permission: $e');
    }
  }

  static bool isWithinBlockedSchedule([DateTime? now]) {
    final current = now ?? DateTime.now();
    final blockedDays = PreferencesService.getRepeatDays();
    final dayIndex = current.weekday - 1;
    if (dayIndex < 0 ||
        dayIndex >= blockedDays.length ||
        !blockedDays[dayIndex]) {
      return false;
    }

    final fromParts = PreferencesService.getBlockFromTime().split(':');
    final untilParts = PreferencesService.getBlockUntilTime().split(':');
    final blockFromMinutes =
        int.parse(fromParts[0]) * 60 + int.parse(fromParts[1]);
    final blockUntilMinutes =
        int.parse(untilParts[0]) * 60 + int.parse(untilParts[1]);
    final currentMinutes = current.hour * 60 + current.minute;

    if (blockFromMinutes <= blockUntilMinutes) {
      return currentMinutes >= blockFromMinutes &&
          currentMinutes < blockUntilMinutes;
    }
    return currentMinutes >= blockFromMinutes ||
        currentMinutes < blockUntilMinutes;
  }

  static bool isStrictLockActive() {
    return PreferencesService.getFocusActive() &&
        PreferencesService.getStrictMode() &&
        isWithinBlockedSchedule() &&
        !PreferencesService.isSmartUnlockActive();
  }

  static Future<void> startFocusSession() async {
    final now = DateTime.now();
    final end = now.add(
      Duration(minutes: PreferencesService.getFocusTimerMinutes()),
    );
    await PreferencesService.setFocusActive(true);
    await PreferencesService.setFocusSessionStartMillis(
      now.millisecondsSinceEpoch,
    );
    await PreferencesService.setFocusSessionEndMillis(end.millisecondsSinceEpoch);
    await PreferencesService.setSessionGrayscaleEnabled(
      PreferencesService.getGrayscaleEnabled(),
    );
    await PreferencesService.setSessionOverlayEnabled(
      PreferencesService.getShowTimeOverlay(),
    );
    await PreferencesService.setSmartUnlockEndMillis(null);
    await startBlocking();
  }

  static Future<void> extendFocusSession({
    int minutes = focusExtensionMinutes,
  }) async {
    final now = DateTime.now();
    final currentEnd = PreferencesService.getFocusSessionEndMillis();
    final base = currentEnd == null || currentEnd < now.millisecondsSinceEpoch
        ? now
        : DateTime.fromMillisecondsSinceEpoch(currentEnd);
    final nextEnd = base.add(Duration(minutes: minutes));
    await PreferencesService.setFocusSessionEndMillis(
      nextEnd.millisecondsSinceEpoch,
    );
    try {
      final nativeEnd = await _channel.invokeMethod<int>('extendFocusSession', {
        'minutes': minutes,
      });
      if (nativeEnd != null && nativeEnd > 0) {
        await PreferencesService.setFocusSessionEndMillis(nativeEnd);
      }
    } on Exception catch (e) {
      debugPrint('Failed to extend focus session natively: $e');
    }
    await startBlocking();
  }

  static Future<void> endFocusSession() async {
    await PreferencesService.setFocusActive(false);
    await PreferencesService.clearFocusSessionState();
    try {
      await _channel.invokeMethod('endFocusSession');
    } on Exception catch (e) {
      debugPrint('Failed to end focus session natively: $e');
    }
    await stopBlocking();
  }

  static Future<void> startSmartUnlock({
    int minutes = smartUnlockDurationMinutes,
  }) async {
    int? nativeEnd;
    try {
      nativeEnd = await _channel.invokeMethod<int>('startSmartUnlock', {
        'minutes': minutes,
      });
    } on Exception catch (e) {
      debugPrint('Failed to start smart unlock natively: $e');
    }
    final end = nativeEnd == null || nativeEnd <= 0
        ? DateTime.now().add(Duration(minutes: minutes)).millisecondsSinceEpoch
        : nativeEnd;
    await PreferencesService.setSmartUnlockEndMillis(end);
    await startBlocking();
  }

  static Future<Map<dynamic, dynamic>> getProtectionRuntimeState() async {
    try {
      final result = await _channel.invokeMethod('getProtectionRuntimeState');
      if (result is Map) {
        return Map<dynamic, dynamic>.from(result);
      }
    } on Exception catch (e) {
      debugPrint('Failed to get protection runtime state: $e');
    }
    return {};
  }

  static Future<void> syncRuntimeStateFromNative() async {
    final runtimeState = await getProtectionRuntimeState();
    if (runtimeState.isEmpty) {
      return;
    }

    final focusActive = runtimeState['focusActive'];
    if (focusActive is bool) {
      await PreferencesService.setFocusActive(focusActive);
    }

    await PreferencesService.setFocusSessionStartMillis(
      _readRuntimeInt(runtimeState['focusSessionStartMillis']),
    );
    await PreferencesService.setFocusSessionEndMillis(
      _readRuntimeInt(runtimeState['focusSessionEndMillis']),
    );
    await PreferencesService.setSmartUnlockEndMillis(
      _readRuntimeInt(runtimeState['smartUnlockEndMillis']),
    );

    final grayscale = runtimeState['sessionGrayscaleEnabled'];
    if (grayscale is bool) {
      await PreferencesService.setSessionGrayscaleEnabled(grayscale);
    }

    final overlay = runtimeState['sessionOverlayEnabled'];
    if (overlay is bool) {
      await PreferencesService.setSessionOverlayEnabled(overlay);
    }
  }

  // ─── Service Control ─────────────────────────────────────────────────────────

  /// Update config and set native blocker active.
  static Future<void> startBlocking() async {
    await _pushConfig(active: true);
  }

  /// Disable native blocker active flag.
  static Future<void> stopBlocking() async {
    await _pushConfig(active: false);
  }

  /// Push full configuration bundle to the native side.
  static Future<void> _pushConfig({required bool active}) async {
    final blockedPackages = PreferencesService.getBlockedPackages();

    // Parse schedule times into total minutes
    final fromStr = PreferencesService.getBlockFromTime();
    final untilStr = PreferencesService.getBlockUntilTime();
    final fromParts = fromStr.split(':');
    final untilParts = untilStr.split(':');
    final blockFromMinutes =
        int.parse(fromParts[0]) * 60 + int.parse(fromParts[1]);
    final blockUntilMinutes =
        int.parse(untilParts[0]) * 60 + int.parse(untilParts[1]);

    // Get blocked days as boolean list
    final days = PreferencesService.getRepeatDays();

    // Get keyword and view blocker config
    final keywords = PreferencesService.getBlockedKeywords();

    try {
      await _channel.invokeMethod('updateBlockingConfig', {
        'blockedPackages': blockedPackages,
        'blockFromMinutes': blockFromMinutes,
        'blockUntilMinutes': blockUntilMinutes,
        'blockedDays': days,
        'active': active,
        'keywords': keywords,
        'blockShorts': PreferencesService.getBlockShorts(),
        'blockReels': PreferencesService.getBlockReels(),
        'blockComments': PreferencesService.getBlockComments(),
        'blockExplore': PreferencesService.getBlockExplore(),
        'grayscaleEnabled': PreferencesService.getGrayscaleEnabled(),
        'showTimeOverlay': PreferencesService.getShowTimeOverlay(),
        'warningTitle': PreferencesService.getWarningTitle(),
        'warningMessage': PreferencesService.getWarningMessage(),
        'strictModeEnabled': PreferencesService.getStrictMode(),
        'smartUnlockEnabled': PreferencesService.getSmartUnlock(),
        'focusSessionStartMillis':
            PreferencesService.getFocusSessionStartMillis() ?? 0,
        'focusSessionEndMillis':
            PreferencesService.getFocusSessionEndMillis() ?? 0,
        'sessionGrayscaleEnabled':
            PreferencesService.getSessionGrayscaleEnabled(),
        'sessionOverlayEnabled': PreferencesService.getSessionOverlayEnabled(),
        'smartUnlockEndMillis':
            PreferencesService.getSmartUnlockEndMillis() ?? 0,
      });
      debugPrint('BlockService: pushed config. Active=$active');
    } on Exception catch (e) {
      debugPrint('Failed to push config to native service: $e');
    }
  }

  /// Restart the service with updated settings.
  static Future<void> restartBlocking() async {
    if (PreferencesService.getFocusActive()) {
      await startBlocking();
    } else {
      await stopBlocking();
    }
  }

  // ─── Anti-Uninstall ─────────────────────────────────────────────────────────

  static Future<bool> enableAntiUninstall() async {
    try {
      final result = await _channel.invokeMethod('enableAntiUninstall');
      return result == true;
    } on Exception {
      return false;
    }
  }

  static Future<void> disableAntiUninstall() async {
    try {
      await _channel.invokeMethod('disableAntiUninstall');
    } on Exception catch (e) {
      debugPrint('Failed to disable anti-uninstall: $e');
    }
  }

  // ─── Grayscale ──────────────────────────────────────────────────────────────

  static Future<void> setGrayscaleMode(bool enabled) async {
    try {
      await _channel.invokeMethod('setGrayscaleMode', {'enabled': enabled});
    } on Exception catch (e) {
      debugPrint('Failed to set grayscale mode: $e');
    }
  }

  // ─── Screen Time Overlay ────────────────────────────────────────────────────

  static Future<void> setShowTimeOverlay(bool show) async {
    try {
      await _channel.invokeMethod('setShowTimeOverlay', {'show': show});
    } on Exception catch (e) {
      debugPrint('Failed to set time overlay: $e');
    }
  }

  static int? _readRuntimeInt(dynamic value) {
    if (value is int) {
      return value > 0 ? value : null;
    }
    if (value is num) {
      final intValue = value.toInt();
      return intValue > 0 ? intValue : null;
    }
    return null;
  }
}
