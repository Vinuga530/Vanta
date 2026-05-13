import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanta/main.dart';
import 'package:vanta/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.focusblocker/blocking');

  setUp(() async {
    SharedPreferences.setMockInitialValues({'focusActive': false});
    await PreferencesService.init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'hasAccessibilityPermission':
            case 'hasDeviceAdminPermission':
              return true;
            case 'getUsageStats':
              return {'apps': []};
            case 'getInstalledApps':
              return <Map<String, String>>[];
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('Vanta app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VantaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Blockers'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Focus Mode'), findsOneWidget);
  });
}
