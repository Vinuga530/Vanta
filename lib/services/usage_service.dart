import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Model for a single app's usage data.
class AppUsageData {
  final String packageName;
  final String appName;
  final int usageMinutes;
  final int openCount;

  AppUsageData({
    required this.packageName,
    required this.appName,
    required this.usageMinutes,
    required this.openCount,
  });

  factory AppUsageData.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageData(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? map['packageName'] ?? '',
      usageMinutes: map['usageMinutes'] ?? 0,
      openCount: map['openCount'] ?? 0,
    );
  }
}

/// Model for daily aggregated stats.
class DailyStats {
  final DateTime date;
  final int totalMinutes;
  final int totalOpens;
  final List<AppUsageData> appUsages;

  DailyStats({
    required this.date,
    required this.totalMinutes,
    required this.totalOpens,
    required this.appUsages,
  });
}

/// Service that fetches app usage data via platform channel.
class UsageService {
  static const _channel = MethodChannel('com.focusblocker/blocking');

  /// Get today's usage stats.
  static Future<DailyStats> getTodayUsage() async {
    try {
      final result = await _channel.invokeMethod('getUsageStats', {
        'daysBack': 0,
      });
      return _parseDailyStats(result, DateTime.now());
    } on Exception catch (e) {
      debugPrint('Failed to get usage stats: $e');
      return DailyStats(
        date: DateTime.now(),
        totalMinutes: 0,
        totalOpens: 0,
        appUsages: [],
      );
    }
  }

  /// Get usage stats for the past N days.
  static Future<List<DailyStats>> getWeeklyUsage() async {
    final List<DailyStats> weekStats = [];

    for (int i = 6; i >= 0; i--) {
      try {
        final result = await _channel.invokeMethod('getUsageStats', {
          'daysBack': i,
        });
        final date = DateTime.now().subtract(Duration(days: i));
        weekStats.add(_parseDailyStats(result, date));
      } on Exception {
        final date = DateTime.now().subtract(Duration(days: i));
        weekStats.add(
          DailyStats(date: date, totalMinutes: 0, totalOpens: 0, appUsages: []),
        );
      }
    }

    return weekStats;
  }

  static DailyStats _parseDailyStats(dynamic result, DateTime date) {
    if (result == null) {
      return DailyStats(
        date: date,
        totalMinutes: 0,
        totalOpens: 0,
        appUsages: [],
      );
    }

    final map = Map<dynamic, dynamic>.from(result);
    final appList =
        (map['apps'] as List<dynamic>?)
            ?.map((e) => AppUsageData.fromMap(Map<dynamic, dynamic>.from(e)))
            .toList() ??
        [];

    // Sort by usage descending
    appList.sort((a, b) => b.usageMinutes.compareTo(a.usageMinutes));

    final totalMin = appList.fold<int>(0, (sum, app) => sum + app.usageMinutes);
    final totalOpens = appList.fold<int>(0, (sum, app) => sum + app.openCount);

    return DailyStats(
      date: date,
      totalMinutes: totalMin,
      totalOpens: totalOpens,
      appUsages: appList,
    );
  }

  /// Get the list of all installed apps.
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      final list = (result as List<dynamic>).map((e) {
        final map = Map<dynamic, dynamic>.from(e);
        return {
          'packageName': map['packageName']?.toString() ?? '',
          'appName': map['appName']?.toString() ?? '',
        };
      }).toList();
      list.sort((a, b) => (a['appName'] ?? '').compareTo(b['appName'] ?? ''));
      return list;
    } on Exception catch (e) {
      debugPrint('Failed to get installed apps: $e');
      return [];
    }
  }
}
