import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usaapp/src/app/di/app_dependencies.dart';
import 'package:usaapp/src/features/chat/domain/entities/conversation.dart';
import 'package:usaapp/src/features/chat/presentation/pages/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Conversation conversation;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    // Use in-memory database for tests
    await AppDependencies.instance.init(executor: NativeDatabase.memory());
  });

  setUp(() async {
    final store = AppDependencies.instance.conversationStore;
    conversation = await store.createConversation('Test Conversation');
  });

  tearDown(() async {
    final store = AppDependencies.instance.conversationStore;
    await store.deleteConversation(conversation.id);
  });

  group('ChatPage', () {
    group('initial state', () {
      testWidgets('displays conversation title in app bar', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        expect(find.text('Test Conversation'), findsOneWidget);
      });

      testWidgets('displays empty state message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        expect(
          find.text('Start a conversation by sending a message.'),
          findsOneWidget,
        );
      });

      testWidgets('displays message input field', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('displays send button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        expect(find.byIcon(Icons.send), findsOneWidget);
      });
    });

    group('sending messages', () {
      testWidgets('displays sent message in chat', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        await tester.enterText(find.byType(TextField), 'Hello, World!');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('Hello, World!'), findsOneWidget);
      });

      testWidgets('clears input field after sending', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
      });

      testWidgets('displays sender label as You for local messages', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        await tester.enterText(find.byType(TextField), 'My message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('You'), findsOneWidget);
      });
    });

    group('multiple messages', () {
      testWidgets('displays first message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        await tester.enterText(find.byType(TextField), 'First message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Second message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('First message'), findsOneWidget);
      });

      testWidgets('displays second message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        await tester.enterText(find.byType(TextField), 'First message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Second message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('Second message'), findsOneWidget);
      });
    });

    group('profile avatars', () {
      testWidgets('displays profile avatar for sent message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatPage(conversation: conversation)),
        );

        await tester.enterText(find.byType(TextField), 'Test');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.byType(CircleAvatar), findsWidgets);
      });
    });
  });
}
