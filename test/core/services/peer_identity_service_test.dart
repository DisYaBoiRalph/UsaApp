import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usaapp/src/core/models/peer_identity.dart';
import 'package:usaapp/src/core/services/peer_identity_service.dart';

void main() {
  late PeerIdentityService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = PeerIdentityService();
  });

  group('PeerIdentityService', () {
    group('getIdentity', () {
      test('generates new id when none exists', () async {
        final identity = await service.getIdentity();

        expect(identity.id, isNotEmpty);
        expect(identity.id.length, equals(16));
      });

      test('returns same id on subsequent calls', () async {
        final first = await service.getIdentity();
        final second = await service.getIdentity();

        expect(first.id, equals(second.id));
      });

      test('returns default display name when none set', () async {
        final identity = await service.getIdentity();

        expect(identity.displayName, isNotEmpty);
      });

      test('returns default role as other', () async {
        final identity = await service.getIdentity();

        expect(identity.role, equals(UserRole.other));
      });
    });

    group('setDisplayName', () {
      test('persists display name', () async {
        await service.setDisplayName('Test Name');
        final identity = await service.getIdentity();

        expect(identity.displayName, equals('Test Name'));
      });

      test('trims whitespace from display name', () async {
        await service.setDisplayName('  Trimmed Name  ');
        final identity = await service.getIdentity();

        expect(identity.displayName, equals('Trimmed Name'));
      });
    });

    group('updateProfile', () {
      test('persists full name', () async {
        await service.updateProfile(name: 'Full Name');
        final identity = await service.getIdentity();

        expect(identity.name, equals('Full Name'));
      });

      test('trims whitespace from full name', () async {
        await service.updateProfile(name: '  Trimmed Name  ');
        final identity = await service.getIdentity();

        expect(identity.name, equals('Trimmed Name'));
      });

      test('removes name when empty string provided', () async {
        await service.updateProfile(name: 'Initial Name');
        await service.updateProfile(name: '');
        final identity = await service.getIdentity();

        expect(identity.name, isNull);
      });

      test('persists profile image', () async {
        await service.updateProfile(profileImage: 'base64imagedata');
        final identity = await service.getIdentity();

        expect(identity.profileImage, equals('base64imagedata'));
      });

      test('removes profile image when empty string provided', () async {
        await service.updateProfile(profileImage: 'initial');
        await service.updateProfile(profileImage: '');
        final identity = await service.getIdentity();

        expect(identity.profileImage, isNull);
      });

      test('persists group name', () async {
        await service.updateProfile(groupName: 'Group A');
        final identity = await service.getIdentity();

        expect(identity.groupName, equals('Group A'));
      });

      test('trims whitespace from group name', () async {
        await service.updateProfile(groupName: '  Group B  ');
        final identity = await service.getIdentity();

        expect(identity.groupName, equals('Group B'));
      });

      test('removes group name when empty string provided', () async {
        await service.updateProfile(groupName: 'Initial');
        await service.updateProfile(groupName: '');
        final identity = await service.getIdentity();

        expect(identity.groupName, isNull);
      });

      test('persists student role', () async {
        await service.updateProfile(role: UserRole.student);
        final identity = await service.getIdentity();

        expect(identity.role, equals(UserRole.student));
      });

      test('persists teacher role', () async {
        await service.updateProfile(role: UserRole.teacher);
        final identity = await service.getIdentity();

        expect(identity.role, equals(UserRole.teacher));
      });

      test('updates multiple fields at once', () async {
        await service.updateProfile(
          name: 'Full Name',
          groupName: 'Group A',
          role: UserRole.student,
        );
        final identity = await service.getIdentity();

        expect(identity.name, equals('Full Name'));
        expect(identity.groupName, equals('Group A'));
        expect(identity.role, equals(UserRole.student));
      });
    });

    group('rememberPeer', () {
      test('stores peer identity', () async {
        const peer = PeerIdentity(
          id: 'peer-1',
          displayName: 'Peer One',
          name: 'Full Peer Name',
          role: UserRole.student,
        );

        await service.rememberPeer(peer);
        final knownPeers = await service.getKnownPeers();

        expect(knownPeers['peer-1'], isNotNull);
        expect(knownPeers['peer-1']!.displayName, equals('Peer One'));
      });

      test('updates existing peer identity', () async {
        const peer1 = PeerIdentity(id: 'peer-1', displayName: 'Original Name');
        const peer2 = PeerIdentity(id: 'peer-1', displayName: 'Updated Name');

        await service.rememberPeer(peer1);
        await service.rememberPeer(peer2);
        final knownPeers = await service.getKnownPeers();

        expect(knownPeers['peer-1']!.displayName, equals('Updated Name'));
      });

      test('ignores peer with empty id', () async {
        const peer = PeerIdentity(id: '', displayName: 'No ID');

        await service.rememberPeer(peer);
        final knownPeers = await service.getKnownPeers();

        expect(knownPeers.isEmpty, isTrue);
      });

      test('stores multiple peers', () async {
        const peer1 = PeerIdentity(id: 'peer-1', displayName: 'Peer One');
        const peer2 = PeerIdentity(id: 'peer-2', displayName: 'Peer Two');

        await service.rememberPeer(peer1);
        await service.rememberPeer(peer2);
        final knownPeers = await service.getKnownPeers();

        expect(knownPeers.length, equals(2));
      });
    });

    group('getKnownPeers', () {
      test('returns empty map initially', () async {
        final knownPeers = await service.getKnownPeers();

        expect(knownPeers, isEmpty);
      });

      test('returns unmodifiable map', () async {
        final knownPeers = await service.getKnownPeers();

        expect(
          () => knownPeers['test'] = const PeerIdentity(
            id: 'test',
            displayName: 'Test',
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('defaultDisplayName', () {
      test('generates display name from id', () {
        final name = service.defaultDisplayName('abc123');

        expect(name, isNotEmpty);
      });
    });
  });
}
