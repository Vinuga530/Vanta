import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;
  static bool _initialized = false;

  // Initialize preferences
  static Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // ─── Focus Toggle ───────────────────────────────────────────────────────────
  static Future<void> setFocusActive(bool value) async {
    if (_initialized) {
      await _prefs.setBool('focusActive', value);
    }
  }

  static bool getFocusActive() {
    if (!_initialized) return true;
    return _prefs.getBool('focusActive') ?? true;
  }

  // ─── App Blocked State ──────────────────────────────────────────────────────
  static Future<void> setAppBlocked(String appName, bool blocked) async {
    if (_initialized) {
      await _prefs.setBool('app_blocked_$appName', blocked);
    }
  }

  static bool getAppBlocked(String appName, bool defaultValue) {
    if (!_initialized) return defaultValue;
    return _prefs.getBool('app_blocked_$appName') ?? defaultValue;
  }

  // ─── Blocked Packages List ─────────────────────────────────────────────────
  static Future<void> setBlockedPackages(List<String> packages) async {
    if (_initialized) {
      await _prefs.setStringList('blockedPackages', packages);
    }
  }

  static List<String> getBlockedPackages() {
    if (!_initialized) return [];
    return _prefs.getStringList('blockedPackages') ?? [];
  }

  // ─── Schedule Times ────────────────────────────────────────────────────────
  static Future<void> setBlockFromTime(String time) async {
    if (_initialized) {
      await _prefs.setString('blockFromTime', time);
    }
  }

  static String getBlockFromTime() {
    if (!_initialized) return '21:00';
    return _prefs.getString('blockFromTime') ?? '21:00';
  }

  static Future<void> setBlockUntilTime(String time) async {
    if (_initialized) {
      await _prefs.setString('blockUntilTime', time);
    }
  }

  static String getBlockUntilTime() {
    if (!_initialized) return '07:00';
    return _prefs.getString('blockUntilTime') ?? '07:00';
  }

  // ─── Days List ────────────────────────────────────────────────────────────
  static Future<void> setRepeatDays(List<bool> days) async {
    if (_initialized) {
      await _prefs.setStringList(
        'repeatDays',
        days.map((d) => d.toString()).toList(),
      );
    }
  }

  static List<bool> getRepeatDays() {
    if (!_initialized) return [true, true, true, true, true, false, false];
    final dayStrings = _prefs.getStringList('repeatDays');
    if (dayStrings == null) {
      return [true, true, true, true, true, false, false];
    }
    return dayStrings.map((d) => d == 'true').toList();
  }

  // ─── Strict Mode ────────────────────────────────────────────────────────────
  static Future<void> setStrictMode(bool value) async {
    if (_initialized) {
      await _prefs.setBool('strictMode', value);
    }
  }

  static bool getStrictMode() {
    if (!_initialized) return true;
    return _prefs.getBool('strictMode') ?? true;
  }

  // ─── Smart Unlock ────────────────────────────────────────────────────────────
  static Future<void> setSmartUnlock(bool value) async {
    if (_initialized) {
      await _prefs.setBool('smartUnlock', value);
    }
  }

  static bool getSmartUnlock() {
    if (!_initialized) return false;
    return _prefs.getBool('smartUnlock') ?? false;
  }

  // ─── Per-App Strict Mode ───────────────────────────────────────────────────
  static Future<void> setAppStrictMode(String appName, bool value) async {
    if (_initialized) {
      await _prefs.setBool('app_strictMode_$appName', value);
    }
  }

  static bool getAppStrictMode(String appName, bool defaultValue) {
    if (!_initialized) return defaultValue;
    return _prefs.getBool('app_strictMode_$appName') ?? defaultValue;
  }

  // ─── Per-App Hide Notifications ────────────────────────────────────────────
  static Future<void> setAppHideNotifications(String appName, bool value) async {
    if (_initialized) {
      await _prefs.setBool('app_hideNotifications_$appName', value);
    }
  }

  static bool getAppHideNotifications(String appName, bool defaultValue) {
    if (!_initialized) return defaultValue;
    return _prefs.getBool('app_hideNotifications_$appName') ?? defaultValue;
  }

  // ─── Theme Mode ─────────────────────────────────────────────────────────────
  static Future<void> setIsDarkMode(bool value) async {
    if (_initialized) {
      await _prefs.setBool('isDarkMode', value);
    }
  }

  static bool getIsDarkMode() {
    if (!_initialized) return false;
    return _prefs.getBool('isDarkMode') ?? false;
  }

  // ─── Blocked Keywords ──────────────────────────────────────────────────────
  static Future<void> setBlockedKeywords(List<String> keywords) async {
    if (_initialized) {
      await _prefs.setStringList('blockedKeywords', keywords);
    }
  }

  static List<String> getBlockedKeywords() {
    if (!_initialized) return [];
    return _prefs.getStringList('blockedKeywords') ?? [];
  }

  // ─── View Blocker Toggles ─────────────────────────────────────────────────
  static Future<void> setBlockShorts(bool value) async {
    if (_initialized) await _prefs.setBool('blockShorts', value);
  }

  static bool getBlockShorts() {
    if (!_initialized) return false;
    return _prefs.getBool('blockShorts') ?? false;
  }

  static Future<void> setBlockReels(bool value) async {
    if (_initialized) await _prefs.setBool('blockReels', value);
  }

  static bool getBlockReels() {
    if (!_initialized) return false;
    return _prefs.getBool('blockReels') ?? false;
  }

  static Future<void> setBlockComments(bool value) async {
    if (_initialized) await _prefs.setBool('blockComments', value);
  }

  static bool getBlockComments() {
    if (!_initialized) return false;
    return _prefs.getBool('blockComments') ?? false;
  }

  static Future<void> setBlockExplore(bool value) async {
    if (_initialized) await _prefs.setBool('blockExplore', value);
  }

  static bool getBlockExplore() {
    if (!_initialized) return false;
    return _prefs.getBool('blockExplore') ?? false;
  }

  // ─── Grayscale Mode ───────────────────────────────────────────────────────
  static Future<void> setGrayscaleEnabled(bool value) async {
    if (_initialized) await _prefs.setBool('grayscaleEnabled', value);
  }

  static bool getGrayscaleEnabled() {
    if (!_initialized) return false;
    return _prefs.getBool('grayscaleEnabled') ?? false;
  }

  // ─── Anti-Uninstall ───────────────────────────────────────────────────────
  static Future<void> setAntiUninstall(bool value) async {
    if (_initialized) await _prefs.setBool('antiUninstall', value);
  }

  static bool getAntiUninstall() {
    if (!_initialized) return false;
    return _prefs.getBool('antiUninstall') ?? false;
  }

  // ─── Warning Screen Customization ─────────────────────────────────────────
  static Future<void> setWarningTitle(String title) async {
    if (_initialized) await _prefs.setString('warningTitle', title);
  }

  static String getWarningTitle() {
    if (!_initialized) return 'Stay Focused';
    return _prefs.getString('warningTitle') ?? 'Stay Focused';
  }

  static Future<void> setWarningMessage(String message) async {
    if (_initialized) await _prefs.setString('warningMessage', message);
  }

  static String getWarningMessage() {
    if (!_initialized) {
      return 'This app is blocked by Vanta. Take a deep breath and reconsider.';
    }
    return _prefs.getString('warningMessage') ??
        'This app is blocked by Vanta. Take a deep breath and reconsider.';
  }

  // ─── Screen Time Overlay ──────────────────────────────────────────────────
  static Future<void> setShowTimeOverlay(bool value) async {
    if (_initialized) await _prefs.setBool('showTimeOverlay', value);
  }

  static bool getShowTimeOverlay() {
    if (!_initialized) return false;
    return _prefs.getBool('showTimeOverlay') ?? false;
  }

  // ─── Focus Timer Duration (minutes) ───────────────────────────────────────
  static Future<void> setFocusTimerMinutes(int minutes) async {
    if (_initialized) await _prefs.setInt('focusTimerMinutes', minutes);
  }

  static int getFocusTimerMinutes() {
    if (!_initialized) return 25;
    return _prefs.getInt('focusTimerMinutes') ?? 25;
  }
}
