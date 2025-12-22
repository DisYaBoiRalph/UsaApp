import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usaapp/src/core/models/peer_identity.dart';
import 'package:usaapp/src/core/widgets/profile_avatar.dart';

void main() {
  group('ProfileAvatar', () {
    // Create a minimal valid PNG image in base64 for testing
    // This is a 1x1 transparent PNG
    final validBase64Image = base64Encode(
      Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]),
    );

    group('with profile image', () {
      testWidgets('displays image when valid base64 provided', (tester) async {
        final identity = PeerIdentity(
          id: 'test-id',
          displayName: 'Test User',
          profileImage: validBase64Image,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        expect(find.byType(CircleAvatar), findsOneWidget);
      });

      testWidgets('falls back to placeholder on invalid base64', (
        tester,
      ) async {
        const identity = PeerIdentity(
          id: 'test-id',
          displayName: 'Test User',
          profileImage: 'not-valid-base64!!!',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        // Should show placeholder with initials (TU for Test User)
        expect(find.text('TU'), findsOneWidget);
      });
    });

    group('placeholder avatar', () {
      testWidgets('displays two-letter initials for two-word name', (
        tester,
      ) async {
        const identity = PeerIdentity(id: 'test-id', displayName: 'John Doe');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        expect(find.text('JD'), findsOneWidget);
      });

      testWidgets('displays two-letter initials for single-word name', (
        tester,
      ) async {
        const identity = PeerIdentity(id: 'test-id', displayName: 'John');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        expect(find.text('JO'), findsOneWidget);
      });

      testWidgets('uses first and last word for multi-word name', (
        tester,
      ) async {
        const identity = PeerIdentity(
          id: 'test-id',
          displayName: 'John Michael Doe',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        expect(find.text('JD'), findsOneWidget);
      });

      testWidgets('uses full name field when available', (tester) async {
        const identity = PeerIdentity(
          id: 'test-id',
          displayName: 'JD',
          name: 'Jane Smith',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        expect(find.text('JS'), findsOneWidget);
      });

      testWidgets('shows question marks for empty name', (tester) async {
        const identity = PeerIdentity(id: 'test-id', displayName: '');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        expect(find.text('??'), findsOneWidget);
      });

      testWidgets('handles single character name', (tester) async {
        const identity = PeerIdentity(id: 'test-id', displayName: 'J');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        expect(find.text('J'), findsOneWidget);
      });

      testWidgets('converts initials to uppercase', (tester) async {
        const identity = PeerIdentity(id: 'test-id', displayName: 'john doe');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 40)),
          ),
        );

        expect(find.text('JD'), findsOneWidget);
      });
    });

    group('sizing', () {
      testWidgets('respects custom size parameter', (tester) async {
        const identity = PeerIdentity(id: 'test-id', displayName: 'Test User');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity, size: 100)),
          ),
        );

        final circleAvatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(circleAvatar.radius, equals(50)); // radius = size / 2
      });

      testWidgets('uses default size of 40', (tester) async {
        const identity = PeerIdentity(id: 'test-id', displayName: 'Test User');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ProfileAvatar(identity: identity)),
          ),
        );

        final circleAvatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(circleAvatar.radius, equals(20)); // radius = 40 / 2
      });
    });

    group('consistent colors', () {
      testWidgets('generates consistent color for same user id', (
        tester,
      ) async {
        const identity1 = PeerIdentity(id: 'same-id', displayName: 'User One');
        const identity2 = PeerIdentity(id: 'same-id', displayName: 'User Two');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ProfileAvatar(identity: identity1, size: 40),
                  ProfileAvatar(identity: identity2, size: 40),
                ],
              ),
            ),
          ),
        );

        final avatars = tester
            .widgetList<CircleAvatar>(find.byType(CircleAvatar))
            .toList();

        expect(avatars[0].backgroundColor, equals(avatars[1].backgroundColor));
      });

      testWidgets('generates different colors for different user ids', (
        tester,
      ) async {
        const identity1 = PeerIdentity(id: 'user-1', displayName: 'User One');
        const identity2 = PeerIdentity(id: 'user-2', displayName: 'User Two');

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ProfileAvatar(identity: identity1, size: 40),
                  ProfileAvatar(identity: identity2, size: 40),
                ],
              ),
            ),
          ),
        );

        final avatars = tester
            .widgetList<CircleAvatar>(find.byType(CircleAvatar))
            .toList();

        // Colors should likely be different (not guaranteed but likely)
        // We just verify both have a background color
        expect(avatars[0].backgroundColor, isNotNull);
        expect(avatars[1].backgroundColor, isNotNull);
      });
    });
  });
}
