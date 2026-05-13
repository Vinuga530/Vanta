import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/preferences_service.dart';
import 'services/block_service.dart';
import 'screens/home_screen.dart';
import 'screens/blockers_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

// Global notifier for dynamic theme switching
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await PreferencesService.init();
    await BlockService.initializeDefaults();
    final isDark = PreferencesService.getIsDarkMode();
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  } catch (e) {
    debugPrint('PreferencesService init warning: $e');
  }

  if (PreferencesService.getFocusActive()) {
    final hasAccessibility = await BlockService.hasAccessibilityPermission();
    final hasDeviceAdmin = await BlockService.hasDeviceAdminPermission();
    if (hasAccessibility && hasDeviceAdmin) {
      BlockService.startBlocking();
    } else {
      await PreferencesService.setFocusActive(false);
    }
  }

  runApp(const VantaApp());
}

class VantaApp extends StatelessWidget {
  const VantaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Vanta',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F2F7),
            colorScheme: const ColorScheme.light(
              primary: CupertinoColors.activeBlue,
              surface: Colors.white,
              onSurface: CupertinoColors.black,
              surfaceContainerLowest: Color(0xFFF2F2F7),
            ),
            fontFamily: '.SF Pro Text',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF2F2F7),
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            colorScheme: const ColorScheme.dark(
              primary: CupertinoColors.activeBlue,
              surface: Color(0xFF1C1C1E),
              onSurface: Colors.white,
              surfaceContainerLowest: Colors.black,
            ),
            fontFamily: '.SF Pro Text',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1C1C1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          home: const MainShell(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BlockersScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        activeColor: CupertinoColors.activeBlue,
        inactiveColor: CupertinoColors.systemGrey,
        backgroundColor: isDark
            ? const Color(0xFF121212).withValues(alpha: 0.9)
            : CupertinoColors.systemBackground.withValues(alpha: 0.9),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.shield_fill),
            label: 'Blockers',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_fill),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear_solid),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
