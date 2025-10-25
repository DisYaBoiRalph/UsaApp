import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offchat/src/app/di/app_dependencies.dart';
import 'package:offchat/src/features/settings/presentation/pages/settings_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppDependencies.instance.init();
  });

  testWidgets('shows P2P setup section', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('P2P Connection Setup'), findsOneWidget);
  });

  testWidgets('displays settings title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });
}
