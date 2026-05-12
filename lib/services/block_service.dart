import 'package:flutter/services.dart';
import 'preferences_service.dart';

/// Service that manages the native Android blocking service.
class BlockService {
  static const _channel = MethodChannel('com.focusblocker/blocking');

  /// Map of app display names to their Android package names.
  static const Map<String, String> appPackageNames = {
    'Instagram': 'com.instagram.android',
    'TikTok': 'com.zhiliaoapp.musically',
    'YouTube': 'com.google.android.youtube',
  };

  // ─── Permission Helpers ──────────────────────────────────────────────────────

  /// Check if the app has Accessibility Service permission.
  static Future<bool> hasAccessibilityPermission() async {
    try {
      final bool result =
          await _channel.invokeMethod('hasAccessibilityPermission');
      return result;
    } on PlatformException {
      return false;
    }
  }

  /// Open the Android Accessibility settings page.
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print('Failed to open Accessibility settings: $e');
    }
  }

  /// Check if usage stats permission is granted.
  static Future<bool> hasUsagePermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasUsagePermission');
      return result;
    } on PlatformException {
      return false;
    }
  }

  /// Open usage access settings.
  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } on PlatformException catch (e) {
      print('Failed to open Usage settings: $e');
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
    // Build list of blocked package names from preferences
    final List<String> blockedPackages = [];

    // Get dynamic blocked packages
    final savedPackages = PreferencesService.getBlockedPackages();
    if (savedPackages.isNotEmpty) {
      blockedPackages.addAll(savedPackages);
    } else {
      // Fallback to hardcoded app entries
      for (final entry in appPackageNames.entries) {
        final defaultBlocked = entry.key != 'YouTube';
        if (PreferencesService.getAppBlocked(entry.key, defaultBlocked)) {
          blockedPackages.add(entry.value);
        }
      }
    }

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
      });
      print('BlockService: pushed config. Active=$active');
    } on PlatformException catch (e) {
      print('Failed to push config to native service: $e');
    }
  }

  /// Restart the service with updated settings.
  static Future<void> restartBlocking() async {
    if (PreferencesService.getFocusActive()) {
      await startBlocking();
    }
  }

  // ─── Anti-Uninstall ─────────────────────────────────────────────────────────

  static Future<bool> enableAntiUninstall() async {
    try {
      final result = await _channel.invokeMethod('enableAntiUninstall');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> disableAntiUninstall() async {
    try {
      await _channel.invokeMethod('disableAntiUninstall');
    } on PlatformException catch (e) {
      print('Failed to disable anti-uninstall: $e');
    }
  }

  // ─── Grayscale ──────────────────────────────────────────────────────────────

  static Future<void> setGrayscaleMode(bool enabled) async {
    try {
      await _channel
          .invokeMethod('setGrayscaleMode', {'enabled': enabled});
    } on PlatformException catch (e) {
      print('Failed to set grayscale mode: $e');
    }
  }

  // ─── Screen Time Overlay ────────────────────────────────────────────────────

  static Future<void> setShowTimeOverlay(bool show) async {
    try {
      await _channel
          .invokeMethod('setShowTimeOverlay', {'show': show});
    } on PlatformException catch (e) {
      print('Failed to set time overlay: $e');
    }
  }
}
