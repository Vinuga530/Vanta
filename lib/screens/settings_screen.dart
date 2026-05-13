import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/preferences_service.dart';
import '../services/block_service.dart';
import '../widgets/ios_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  late bool _strictMode, _smartUnlock, _grayscale, _timeOverlay;
  late TimeOfDay _blockFrom, _blockUntil;
  late List<bool> _days;
  late int _focusMinutes;
  bool _deviceAdminEnabled = false;
  final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _strictMode = PreferencesService.getStrictMode();
    _smartUnlock = PreferencesService.getSmartUnlock();
    _grayscale = PreferencesService.getGrayscaleEnabled();
    _timeOverlay = PreferencesService.getShowTimeOverlay();
    _days = PreferencesService.getRepeatDays();
    _focusMinutes = PreferencesService.getFocusTimerMinutes();

    final f = PreferencesService.getBlockFromTime().split(':');
    final u = PreferencesService.getBlockUntilTime().split(':');
    _blockFrom = TimeOfDay(hour: int.parse(f[0]), minute: int.parse(f[1]));
    _blockUntil = TimeOfDay(hour: int.parse(u[0]), minute: int.parse(u[1]));
    _loadDeviceAdminStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDeviceAdminStatus();
    }
  }

  Future<void> _loadDeviceAdminStatus() async {
    final enabled = await BlockService.hasDeviceAdminPermission();
    if (mounted) {
      setState(() => _deviceAdminEnabled = enabled);
    }
  }

  void _toggleTheme() {
    final cur = themeNotifier.value;
    final next = cur == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeNotifier.value = next;
    PreferencesService.setIsDarkMode(next == ThemeMode.dark);
    HapticFeedback.mediumImpact();
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _blockFrom : _blockUntil,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: Theme.of(
            c,
          ).colorScheme.copyWith(primary: CupertinoColors.activeBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _blockFrom = picked;
          PreferencesService.setBlockFromTime(
            '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}',
          );
        } else {
          _blockUntil = picked;
          PreferencesService.setBlockUntilTime(
            '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      });
      BlockService.restartBlocking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Settings'),
            border: null,
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.8)
                : const Color(0xFFF2F2F7).withValues(alpha: 0.8),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // ─── APPEARANCE ──────────────────────────────────────
              IOSGroup(
                header: 'Appearance',
                children: [
                  IOSListTile(
                    leading: IOSIconBadge(
                      icon: isDark
                          ? CupertinoIcons.moon_fill
                          : CupertinoIcons.sun_max_fill,
                      color: isDark
                          ? const Color(0xFF5E5CE6)
                          : const Color(0xFFFF9F0A),
                    ),
                    title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
                    subtitle: const Text('Toggle app appearance'),
                    trailing: CupertinoSwitch(
                      value: isDark,
                      activeTrackColor: CupertinoColors.activeBlue,
                      onChanged: (_) => _toggleTheme(),
                    ),
                  ),
                ],
              ),

              // ─── SCHEDULE ────────────────────────────────────────
              IOSGroup(
                header: 'Schedule',
                children: [
                  IOSListTile(
                    title: const Text('From'),
                    trailing: Text(
                      _fmtTime(_blockFrom),
                      style: const TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 17,
                      ),
                    ),
                    onTap: () => _pickTime(true),
                  ),
                  IOSListTile(
                    title: const Text('Until'),
                    trailing: Text(
                      _fmtTime(_blockUntil),
                      style: const TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 17,
                      ),
                    ),
                    onTap: () => _pickTime(false),
                  ),
                ],
              ),

              // ─── REPEAT DAYS ─────────────────────────────────────
              IOSGroup(
                header: 'Repeat Days',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final sel = _days[i];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _days[i] = !_days[i]);
                            PreferencesService.setRepeatDays(_days);
                            HapticFeedback.selectionClick();
                            BlockService.restartBlocking();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sel
                                  ? CupertinoColors.activeBlue
                                  : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFE5E5EA)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              dayLabels[i],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),

              // ─── FOCUS TIMER ─────────────────────────────────────
              IOSGroup(
                header: 'Focus Timer',
                footer:
                    'Focus timer starts automatically when you enable Focus Mode.',
                children: [
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.timer,
                      color: Color(0xFFFF9F0A),
                    ),
                    title: const Text('Timer Duration'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_focusMinutes min',
                          style: const TextStyle(
                            color: CupertinoColors.activeBlue,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ],
                    ),
                    onTap: () => _showTimerPicker(),
                  ),
                ],
              ),

              // ─── PROTECTIONS ─────────────────────────────────────
              IOSGroup(
                header: 'Protections',
                children: [
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.lock_shield_fill,
                      color: Color(0xFFFF453A),
                    ),
                    title: const Text('Strict Mode'),
                    subtitle: const Text('Prevent disabling during focus'),
                    trailing: CupertinoSwitch(
                      value: _strictMode,
                      activeTrackColor: CupertinoColors.activeBlue,
                      onChanged: (v) {
                        setState(() => _strictMode = v);
                        PreferencesService.setStrictMode(v);
                      },
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.bolt_fill,
                      color: Color(0xFF30D158),
                    ),
                    title: const Text('Smart Unlock'),
                    subtitle: const Text('Emergency override window'),
                    trailing: CupertinoSwitch(
                      value: _smartUnlock,
                      activeTrackColor: CupertinoColors.activeBlue,
                      onChanged: (v) {
                        setState(() => _smartUnlock = v);
                        PreferencesService.setSmartUnlock(v);
                      },
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.circle_lefthalf_fill,
                      color: Color(0xFF8E8E93),
                    ),
                    title: const Text('Grayscale Mode'),
                    subtitle: const Text('Make blocked apps boring'),
                    trailing: CupertinoSwitch(
                      value: _grayscale,
                      activeTrackColor: CupertinoColors.activeBlue,
                      onChanged: (v) {
                        setState(() => _grayscale = v);
                        PreferencesService.setGrayscaleEnabled(v);
                        BlockService.setGrayscaleMode(v);
                      },
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.clock_fill,
                      color: Color(0xFF64D2FF),
                    ),
                    title: const Text('Screen Time Overlay'),
                    subtitle: const Text('Show timer on blocked apps'),
                    trailing: CupertinoSwitch(
                      value: _timeOverlay,
                      activeTrackColor: CupertinoColors.activeBlue,
                      onChanged: (v) {
                        setState(() => _timeOverlay = v);
                        PreferencesService.setShowTimeOverlay(v);
                        BlockService.setShowTimeOverlay(v);
                      },
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.trash_slash_fill,
                      color: Color(0xFFBF5AF2),
                    ),
                    title: const Text('Device Administrator'),
                    subtitle: Text(
                      _deviceAdminEnabled
                          ? 'Enabled and ready for Focus Mode'
                          : 'Required before Focus Mode can be enabled',
                    ),
                    trailing: Text(
                      _deviceAdminEnabled ? 'Enabled' : 'Required',
                      style: TextStyle(
                        color: _deviceAdminEnabled
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.destructiveRed,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _deviceAdminEnabled
                        ? null
                        : BlockService.requestDeviceAdminPermission,
                  ),
                ],
              ),

              // ─── WARNING SCREEN ──────────────────────────────────
              IOSGroup(
                header: 'Warning Screen',
                footer:
                    'This message appears when a user tries to open a blocked app.',
                children: [
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.exclamationmark_shield_fill,
                      color: Color(0xFFFF9F0A),
                    ),
                    title: const Text('Customize Message'),
                    trailing: const Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    onTap: () => _showWarningEditor(),
                  ),
                ],
              ),

              // ─── ABOUT ───────────────────────────────────────────
              IOSGroup(
                header: 'About',
                children: [
                  const IOSListTile(
                    title: Text('App Name'),
                    trailing: Text('Vanta'),
                  ),
                  const IOSListTile(
                    title: Text('Version'),
                    trailing: Text('1.0.0'),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.shield_fill,
                      color: CupertinoColors.activeBlue,
                    ),
                    title: const Text('Permissions'),
                    trailing: const Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    onTap: () => BlockService.openAccessibilitySettings(),
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

  void _showTimerPicker() {
    final options = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Focus Timer Duration'),
        actions: options
            .map(
              (m) => CupertinoActionSheetAction(
                isDefaultAction: m == _focusMinutes,
                child: Text('$m minutes'),
                onPressed: () {
                  setState(() => _focusMinutes = m);
                  PreferencesService.setFocusTimerMinutes(m);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showWarningEditor() {
    final titleCtrl = TextEditingController(
      text: PreferencesService.getWarningTitle(),
    );
    final msgCtrl = TextEditingController(
      text: PreferencesService.getWarningMessage(),
    );

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Warning Screen'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: titleCtrl,
              placeholder: 'Title',
              padding: const EdgeInsets.all(10),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: msgCtrl,
              placeholder: 'Message',
              padding: const EdgeInsets.all(10),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              PreferencesService.setWarningTitle(titleCtrl.text);
              PreferencesService.setWarningMessage(msgCtrl.text);
              BlockService.restartBlocking();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
