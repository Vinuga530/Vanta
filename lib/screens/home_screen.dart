import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/preferences_service.dart';
import '../services/block_service.dart';
import '../services/usage_service.dart';
import '../widgets/ios_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late bool focusActive;
  bool _isCheckingPermissions = false;
  int _todayMinutes = 0;
  int _appsBlocked = 0;
  int _totalOpens = 0;
  Timer? _focusTimer;
  int _focusSecondsRemaining = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    focusActive = PreferencesService.getFocusActive();
    _appsBlocked = PreferencesService.getBlockedPackages().length;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadUsageData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRequiredPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkRequiredPermissions();
    }
  }

  Future<void> _loadUsageData() async {
    try {
      final stats = await UsageService.getTodayUsage();
      if (mounted) {
        setState(() {
          _todayMinutes = stats.totalMinutes;
          _totalOpens = stats.totalOpens;
        });
      }
    } catch (_) {}
  }

  Future<bool> _checkRequiredPermissions({bool showDialogs = true}) async {
    if (_isCheckingPermissions) return false;
    _isCheckingPermissions = true;

    try {
      final hasAccessibility = await BlockService.hasAccessibilityPermission();
      if (!hasAccessibility) {
        await _disableFocusModeIfNeeded();
        if (mounted && showDialogs) {
          _showAccessibilityDialog();
        }
        return false;
      }

      final hasDeviceAdmin = await BlockService.hasDeviceAdminPermission();
      if (!hasDeviceAdmin) {
        await _disableFocusModeIfNeeded();
        if (mounted && showDialogs) {
          _showDeviceAdminDialog();
        }
        return false;
      }

      return true;
    } finally {
      _isCheckingPermissions = false;
    }
  }

  Future<void> _disableFocusModeIfNeeded() async {
    if (!focusActive) return;

    _focusTimer?.cancel();
    setState(() {
      focusActive = false;
      _focusSecondsRemaining = 0;
    });
    await PreferencesService.setFocusActive(false);
    await BlockService.stopBlocking();
  }

  void _showAccessibilityDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Accessibility Required'),
        content: const Text(
          'Vanta needs Accessibility Access to block distracting apps and content in real-time.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Later'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Settings'),
            onPressed: () {
              Navigator.pop(ctx);
              BlockService.openAccessibilitySettings();
            },
          ),
        ],
      ),
    );
  }

  void _showDeviceAdminDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Device Admin Required'),
        content: const Text(
          'Vanta requires Android device administrator access before Focus Mode can be enabled.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Later'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Grant Access'),
            onPressed: () {
              Navigator.pop(ctx);
              BlockService.requestDeviceAdminPermission();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFocus(bool value) async {
    if (value) {
      final hasPermissions = await _checkRequiredPermissions();
      if (!hasPermissions) {
        return;
      }
    }

    setState(() => focusActive = value);
    PreferencesService.setFocusActive(value);
    HapticFeedback.mediumImpact();

    if (value) {
      BlockService.startBlocking();
      _startFocusTimer();
    } else {
      BlockService.stopBlocking();
      _focusTimer?.cancel();
      setState(() => _focusSecondsRemaining = 0);
    }
  }

  void _startFocusTimer() {
    final minutes = PreferencesService.getFocusTimerMinutes();
    setState(() => _focusSecondsRemaining = minutes * 60);
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_focusSecondsRemaining > 0) {
        setState(() => _focusSecondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenTimeLimit = 4 * 60; // 4 hour target
    final progress = (_todayMinutes / screenTimeLimit).clamp(0.0, 1.0);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Vanta'),
            border: null,
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.8)
                : const Color(0xFFF2F2F7).withValues(alpha: 0.8),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // ─── Focus Mode Hero Card ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: focusActive
                          ? [const Color(0xFF34C759), const Color(0xFF30D158)]
                          : [const Color(0xFF636366), const Color(0xFF48484A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (focusActive
                                    ? const Color(0xFF34C759)
                                    : const Color(0xFF636366))
                                .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, child) {
                              final scale = focusActive
                                  ? 1.0 + (_pulseController.value * 0.1)
                                  : 1.0;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                focusActive
                                    ? CupertinoIcons.shield_fill
                                    : CupertinoIcons.shield,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Focus Mode',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  focusActive
                                      ? 'Shields are Up'
                                      : 'Shields are Down',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: focusActive,
                            activeTrackColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            thumbColor: Colors.white,
                            onChanged: _toggleFocus,
                          ),
                        ],
                      ),
                      if (focusActive && _focusSecondsRemaining > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.timer,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimer(_focusSecondsRemaining),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Screen Time Ring ─────────────────────────────────
              Center(
                child: CircularProgressRing(
                  progress: progress,
                  centerText: _formatDuration(_todayMinutes),
                  subtitle: 'today',
                  size: 140,
                  trackColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  progressColor: progress > 0.75
                      ? CupertinoColors.destructiveRed
                      : progress > 0.5
                      ? CupertinoColors.activeOrange
                      : CupertinoColors.activeBlue,
                  strokeWidth: 12,
                ),
              ),

              const SizedBox(height: 24),

              // ─── Quick Stats Grid ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedStatCard(
                        title: 'Blocked',
                        value: '$_appsBlocked',
                        icon: CupertinoIcons.nosign,
                        gradientColors: const [
                          Color(0xFFFF453A),
                          Color(0xFFFF6961),
                        ],
                        subtitle: 'apps restricted',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedStatCard(
                        title: 'Unlocks',
                        value: '$_totalOpens',
                        icon: CupertinoIcons.device_phone_portrait,
                        gradientColors: const [
                          Color(0xFF5E5CE6),
                          Color(0xFF7D7AFF),
                        ],
                        subtitle: 'times today',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedStatCard(
                  title: 'Time Saved',
                  value: _formatDuration(
                    (screenTimeLimit - _todayMinutes).clamp(0, 9999),
                  ),
                  icon: CupertinoIcons.clock_fill,
                  gradientColors: const [Color(0xFF30D158), Color(0xFF63E688)],
                  subtitle: 'compared to 4h daily target',
                ),
              ),

              // ─── Active Protections Summary ───────────────────────
              IOSGroup(
                header: 'Active Protections',
                children: [
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.app_badge_fill,
                      color: Color(0xFFFF453A),
                    ),
                    title: const Text('App Blocker'),
                    trailing: Text(
                      '$_appsBlocked apps',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.textformat_abc,
                      color: Color(0xFFFF9F0A),
                    ),
                    title: const Text('Keyword Blocker'),
                    trailing: Text(
                      '${PreferencesService.getBlockedKeywords().length} keywords',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.eye_slash_fill,
                      color: Color(0xFF5E5CE6),
                    ),
                    title: const Text('View Blocker'),
                    trailing: Text(
                      _countActiveViewBlockers(),
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  String _countActiveViewBlockers() {
    int count = 0;
    if (PreferencesService.getBlockShorts()) count++;
    if (PreferencesService.getBlockReels()) count++;
    if (PreferencesService.getBlockComments()) count++;
    if (PreferencesService.getBlockExplore()) count++;
    return '$count active';
  }
}
