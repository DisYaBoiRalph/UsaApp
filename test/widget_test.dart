// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usaapp/src/app/di/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await AppDependencies.instance.init(executor: NativeDatabase.memory());
  });

  group('AppDependencies', () {
    test('initializes successfully', () {
      expect(AppDependencies.instance, isNotNull);
    });

    test('provides peer identity after initialization', () {
      expect(AppDependencies.instance.peerIdentity, isNotNull);
    });

    test('provides conversation store after initialization', () {
      expect(AppDependencies.instance.conversationStore, isNotNull);
    });
  });
}
