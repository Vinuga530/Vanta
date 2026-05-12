import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/preferences_service.dart';
import '../services/block_service.dart';
import '../services/usage_service.dart';
import '../widgets/ios_components.dart';
import 'app_picker_screen.dart';

class BlockersScreen extends StatefulWidget {
  const BlockersScreen({super.key});

  @override
  State<BlockersScreen> createState() => _BlockersScreenState();
}

class _BlockersScreenState extends State<BlockersScreen> {
  late List<String> _blockedPackages;
  late List<String> _keywords;
  late bool _blockShorts;
  late bool _blockReels;
  late bool _blockComments;
  late bool _blockExplore;
  final _keywordController = TextEditingController();

  // Map package names to display names (cached)
  final Map<String, String> _appNames = {};

  @override
  void initState() {
    super.initState();
    _blockedPackages = PreferencesService.getBlockedPackages();
    _keywords = PreferencesService.getBlockedKeywords();
    _blockShorts = PreferencesService.getBlockShorts();
    _blockReels = PreferencesService.getBlockReels();
    _blockComments = PreferencesService.getBlockComments();
    _blockExplore = PreferencesService.getBlockExplore();
    _loadAppNames();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadAppNames() async {
    final apps = await UsageService.getInstalledApps();
    for (final app in apps) {
      _appNames[app['packageName'] ?? ''] = app['appName'] ?? '';
    }
    if (mounted) setState(() {});
  }

  String _getAppName(String pkg) {
    return _appNames[pkg] ?? pkg.split('.').last;
  }

  void _removeBlockedApp(String pkg) {
    setState(() => _blockedPackages.remove(pkg));
    PreferencesService.setBlockedPackages(_blockedPackages);
    BlockService.restartBlocking();
    HapticFeedback.lightImpact();
  }

  void _addKeyword(String keyword) {
    if (keyword.trim().isEmpty) return;
    final kw = keyword.trim().toLowerCase();
    if (_keywords.contains(kw)) return;

    setState(() => _keywords.add(kw));
    PreferencesService.setBlockedKeywords(_keywords);
    _keywordController.clear();
    BlockService.restartBlocking();
    HapticFeedback.lightImpact();
  }

  void _removeKeyword(String keyword) {
    setState(() => _keywords.remove(keyword));
    PreferencesService.setBlockedKeywords(_keywords);
    BlockService.restartBlocking();
  }

  void _updateViewBlocker(String type, bool value) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (type) {
        case 'shorts':
          _blockShorts = value;
          PreferencesService.setBlockShorts(value);
          break;
        case 'reels':
          _blockReels = value;
          PreferencesService.setBlockReels(value);
          break;
        case 'comments':
          _blockComments = value;
          PreferencesService.setBlockComments(value);
          break;
        case 'explore':
          _blockExplore = value;
          PreferencesService.setBlockExplore(value);
          break;
      }
    });
    BlockService.restartBlocking();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Blockers'),
            border: null,
            backgroundColor: isDark
                ? Colors.black.withOpacity(0.8)
                : const Color(0xFFF2F2F7).withOpacity(0.8),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // ─── APP BLOCKER ──────────────────────────────────────
              IOSGroup(
                header: 'App Blocker',
                children: [
                  if (_blockedPackages.isEmpty)
                    const IOSListTile(
                      leading: Icon(CupertinoIcons.info_circle,
                          color: CupertinoColors.systemGrey, size: 22),
                      title: Text('No apps blocked',
                          style: TextStyle(color: CupertinoColors.systemGrey)),
                    ),
                  for (final pkg in _blockedPackages)
                    IOSListTile(
                      leading: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _colorForPackage(pkg),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getAppName(pkg).isNotEmpty
                              ? _getAppName(pkg)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      title: Text(_getAppName(pkg)),
                      subtitle: Text(pkg,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 24,
                        child: const Icon(CupertinoIcons.minus_circle_fill,
                            color: CupertinoColors.destructiveRed, size: 22),
                        onPressed: () => _removeBlockedApp(pkg),
                      ),
                    ),
                  IOSListTile(
                    leading: const Icon(CupertinoIcons.plus_circle_fill,
                        color: CupertinoColors.activeBlue, size: 30),
                    title: const Text('Add Application',
                        style: TextStyle(color: CupertinoColors.activeBlue)),
                    onTap: () async {
                      final result = await Navigator.push<List<String>>(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => AppPickerScreen(
                              alreadyBlocked: _blockedPackages),
                        ),
                      );
                      if (result != null) {
                        setState(() => _blockedPackages = result);
                        PreferencesService.setBlockedPackages(result);
                        BlockService.restartBlocking();
                      }
                    },
                  ),
                ],
                footer:
                    '${_blockedPackages.length} app(s) will be blocked when Focus Mode is active.',
              ),

              // ─── KEYWORD BLOCKER ──────────────────────────────────
              IOSGroup(
                header: 'Keyword Blocker',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            controller: _keywordController,
                            placeholder: 'Enter keyword to block...',
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE5E5EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 15),
                            onSubmitted: _addKeyword,
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(CupertinoIcons.plus_circle_fill,
                              color: CupertinoColors.activeBlue, size: 28),
                          onPressed: () =>
                              _addKeyword(_keywordController.text),
                        ),
                      ],
                    ),
                  ),
                  for (final kw in _keywords)
                    IOSListTile(
                      leading: const IOSIconBadge(
                        icon: CupertinoIcons.textformat_abc,
                        color: Color(0xFFFF9F0A),
                        size: 28,
                      ),
                      title: Text(kw),
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 24,
                        child: const Icon(CupertinoIcons.minus_circle_fill,
                            color: CupertinoColors.destructiveRed, size: 22),
                        onPressed: () => _removeKeyword(kw),
                      ),
                    ),
                ],
                footer:
                    'Content containing these keywords will be blocked in browser and apps.',
              ),

              // ─── VIEW BLOCKER ─────────────────────────────────────
              IOSGroup(
                header: 'View Blocker',
                children: [
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.play_rectangle_fill,
                      color: Color(0xFFFF2D55),
                    ),
                    title: const Text('YouTube Shorts'),
                    subtitle: const Text('Block short-form video feed'),
                    trailing: CupertinoSwitch(
                      value: _blockShorts,
                      activeColor: CupertinoColors.activeBlue,
                      onChanged: (v) => _updateViewBlocker('shorts', v),
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.videocam_fill,
                      color: Color(0xFFE1306C),
                    ),
                    title: const Text('Instagram Reels'),
                    subtitle: const Text('Block Reels tab and feed'),
                    trailing: CupertinoSwitch(
                      value: _blockReels,
                      activeColor: CupertinoColors.activeBlue,
                      onChanged: (v) => _updateViewBlocker('reels', v),
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.bubble_left_bubble_right_fill,
                      color: Color(0xFF5E5CE6),
                    ),
                    title: const Text('Comments'),
                    subtitle: const Text('Hide comment sections'),
                    trailing: CupertinoSwitch(
                      value: _blockComments,
                      activeColor: CupertinoColors.activeBlue,
                      onChanged: (v) => _updateViewBlocker('comments', v),
                    ),
                  ),
                  IOSListTile(
                    leading: const IOSIconBadge(
                      icon: CupertinoIcons.compass_fill,
                      color: Color(0xFFFF9F0A),
                    ),
                    title: const Text('Explore / Discover'),
                    subtitle: const Text('Block explore/discover feeds'),
                    trailing: CupertinoSwitch(
                      value: _blockExplore,
                      activeColor: CupertinoColors.activeBlue,
                      onChanged: (v) => _updateViewBlocker('explore', v),
                    ),
                  ),
                ],
                footer:
                    'View blockers use Accessibility Service to detect and dismiss specific in-app content.',
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Color _colorForPackage(String pkg) {
    final hash = pkg.hashCode;
    final colors = [
      const Color(0xFFFF453A),
      const Color(0xFFFF9F0A),
      const Color(0xFF30D158),
      const Color(0xFF5E5CE6),
      const Color(0xFFBF5AF2),
      const Color(0xFF64D2FF),
      const Color(0xFFFF6482),
      const Color(0xFFAC8E68),
    ];
    return colors[hash.abs() % colors.length];
  }
}
