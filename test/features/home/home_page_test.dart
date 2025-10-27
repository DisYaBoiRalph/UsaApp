import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usaapp/src/app/di/app_dependencies.dart';
import 'package:usaapp/src/features/home/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await AppDependencies.instance.init();
  });

  testWidgets('displays navigation cards', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('View Chats'), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('shows welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to UsaApp'), findsOneWidget);
  });
}
