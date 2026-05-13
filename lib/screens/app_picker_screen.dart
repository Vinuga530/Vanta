import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import '../widgets/ios_components.dart';

class AppPickerScreen extends StatefulWidget {
  final List<String> alreadyBlocked;
  const AppPickerScreen({super.key, required this.alreadyBlocked});
  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  List<Map<String, String>> _allApps = [];
  List<Map<String, String>> _filtered = [];
  late Set<String> _selected;
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.alreadyBlocked);
    _loadApps();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    final apps = await UsageService.getInstalledApps();
    if (mounted) {
      setState(() {
        _allApps = apps;
        _filtered = apps;
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _allApps.where((a) {
        return (a['appName'] ?? '').toLowerCase().contains(lower) ||
            (a['packageName'] ?? '').toLowerCase().contains(lower);
      }).toList();
    });
  }

  Color _color(String p) {
    const c = [
      Color(0xFFFF453A),
      Color(0xFFFF9F0A),
      Color(0xFF30D158),
      Color(0xFF5E5CE6),
      Color(0xFFBF5AF2),
      Color(0xFF64D2FF),
      Color(0xFFFF6482),
      Color(0xFFAC8E68),
    ];
    return c[p.hashCode.abs() % c.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            children: [
              Icon(CupertinoIcons.chevron_back),
              Text('Back', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 100,
        title: const Text('Select Apps'),
        actions: [
          CupertinoButton(
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () => Navigator.pop(context, _selected.toList()),
          ),
        ],
      ),
      body: Column(
        children: [
          IOSSearchBar(
            controller: _searchCtrl,
            placeholder: 'Search apps...',
            onChanged: _filter,
          ),
          if (_loading)
            const Expanded(child: Center(child: CupertinoActivityIndicator()))
          else
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final app = _filtered[i];
                  final pkg = app['packageName'] ?? '';
                  final name = app['appName'] ?? pkg;
                  final isSel = _selected.contains(pkg);
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isDark
                                ? const Color(0xFF1A2A1A)
                                : const Color(0xFFE8F5E9))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _color(pkg),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontSize: 15)),
                      subtitle: Text(
                        pkg,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.systemGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        isSel
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        color: isSel
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.systemGrey,
                        size: 24,
                      ),
                      onTap: () => setState(() {
                        if (isSel) {
                          _selected.remove(pkg);
                        } else {
                          _selected.add(pkg);
                        }
                      }),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
