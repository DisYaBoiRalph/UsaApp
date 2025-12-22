import 'package:flutter_test/flutter_test.dart';
import 'package:usaapp/src/core/models/peer_identity.dart';

void main() {
  group('UserRole', () {
    test('student role returns correct display name', () {
      expect(UserRole.student.displayName, equals('Student'));
    });

    test('teacher role returns correct display name', () {
      expect(UserRole.teacher.displayName, equals('Teacher'));
    });

    test('other role returns correct display name', () {
      expect(UserRole.other.displayName, equals('Other'));
    });
  });

  group('PeerIdentity', () {
    test('creates identity with required fields', () {
      const identity = PeerIdentity(id: 'test-id', displayName: 'Test User');

      expect(identity.id, equals('test-id'));
      expect(identity.displayName, equals('Test User'));
    });

    test('creates identity with default role as other', () {
      const identity = PeerIdentity(id: 'test-id', displayName: 'Test User');

      expect(identity.role, equals(UserRole.other));
    });

    test('creates identity with all optional fields', () {
      const identity = PeerIdentity(
        id: 'test-id',
        displayName: 'Test User',
        name: 'Full Name',
        profileImage: 'base64string',
        groupName: 'Group A',
        role: UserRole.student,
      );

      expect(identity.name, equals('Full Name'));
      expect(identity.profileImage, equals('base64string'));
      expect(identity.groupName, equals('Group A'));
      expect(identity.role, equals(UserRole.student));
    });

    test('optional fields default to null', () {
      const identity = PeerIdentity(id: 'test-id', displayName: 'Test User');

      expect(identity.name, isNull);
      expect(identity.profileImage, isNull);
      expect(identity.groupName, isNull);
    });

    group('copyWith', () {
      test('copies identity with new id', () {
        const original = PeerIdentity(
          id: 'original-id',
          displayName: 'Original',
        );
        final copied = original.copyWith(id: 'new-id');

        expect(copied.id, equals('new-id'));
        expect(copied.displayName, equals('Original'));
      });

      test('copies identity with new display name', () {
        const original = PeerIdentity(id: 'test-id', displayName: 'Original');
        final copied = original.copyWith(displayName: 'Updated');

        expect(copied.displayName, equals('Updated'));
      });

      test('copies identity with new name', () {
        const original = PeerIdentity(
          id: 'test-id',
          displayName: 'Display',
          name: 'Original Name',
        );
        final copied = original.copyWith(name: 'New Name');

        expect(copied.name, equals('New Name'));
      });

      test('copies identity with new profile image', () {
        const original = PeerIdentity(id: 'test-id', displayName: 'Display');
        final copied = original.copyWith(profileImage: 'newbase64');

        expect(copied.profileImage, equals('newbase64'));
      });

      test('copies identity with new group name', () {
        const original = PeerIdentity(id: 'test-id', displayName: 'Display');
        final copied = original.copyWith(groupName: 'New Group');

        expect(copied.groupName, equals('New Group'));
      });

      test('copies identity with new role', () {
        const original = PeerIdentity(
          id: 'test-id',
          displayName: 'Display',
          role: UserRole.student,
        );
        final copied = original.copyWith(role: UserRole.teacher);

        expect(copied.role, equals(UserRole.teacher));
      });

      test('preserves original values when not specified', () {
        const original = PeerIdentity(
          id: 'test-id',
          displayName: 'Display',
          name: 'Full Name',
          profileImage: 'image',
          groupName: 'Group',
          role: UserRole.student,
        );
        final copied = original.copyWith();

        expect(copied.id, equals(original.id));
        expect(copied.displayName, equals(original.displayName));
        expect(copied.name, equals(original.name));
        expect(copied.profileImage, equals(original.profileImage));
        expect(copied.groupName, equals(original.groupName));
        expect(copied.role, equals(original.role));
      });
    });

    group('toJson', () {
      test('serializes required fields', () {
        const identity = PeerIdentity(id: 'test-id', displayName: 'Test User');
        final json = identity.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['displayName'], equals('Test User'));
      });

      test('serializes role as string', () {
        const identity = PeerIdentity(
          id: 'test-id',
          displayName: 'Test User',
          role: UserRole.student,
        );
        final json = identity.toJson();

        expect(json['role'], equals('student'));
      });

      test('serializes optional fields when present', () {
        const identity = PeerIdentity(
          id: 'test-id',
          displayName: 'Test User',
          name: 'Full Name',
          profileImage: 'base64image',
          groupName: 'Group A',
        );
        final json = identity.toJson();

        expect(json['name'], equals('Full Name'));
        expect(json['profileImage'], equals('base64image'));
        expect(json['groupName'], equals('Group A'));
      });

      test('serializes null optional fields as null', () {
        const identity = PeerIdentity(id: 'test-id', displayName: 'Test User');
        final json = identity.toJson();

        expect(json['name'], isNull);
        expect(json['profileImage'], isNull);
        expect(json['groupName'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes required fields', () {
        final json = {
          'id': 'test-id',
          'displayName': 'Test User',
          'role': 'other',
        };
        final identity = PeerIdentity.fromJson(json);

        expect(identity.id, equals('test-id'));
        expect(identity.displayName, equals('Test User'));
      });

      test('deserializes student role', () {
        final json = {
          'id': 'test-id',
          'displayName': 'Test User',
          'role': 'student',
        };
        final identity = PeerIdentity.fromJson(json);

        expect(identity.role, equals(UserRole.student));
      });

      test('deserializes teacher role', () {
        final json = {
          'id': 'test-id',
          'displayName': 'Test User',
          'role': 'teacher',
        };
        final identity = PeerIdentity.fromJson(json);

        expect(identity.role, equals(UserRole.teacher));
      });

      test('defaults to other role for unknown role value', () {
        final json = {
          'id': 'test-id',
          'displayName': 'Test User',
          'role': 'unknown_role',
        };
        final identity = PeerIdentity.fromJson(json);

        expect(identity.role, equals(UserRole.other));
      });

      test('deserializes optional fields when present', () {
        final json = {
          'id': 'test-id',
          'displayName': 'Test User',
          'name': 'Full Name',
          'profileImage': 'base64image',
          'groupName': 'Group A',
          'role': 'student',
        };
        final identity = PeerIdentity.fromJson(json);

        expect(identity.name, equals('Full Name'));
        expect(identity.profileImage, equals('base64image'));
        expect(identity.groupName, equals('Group A'));
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'test-id',
          'displayName': 'Test User',
          'name': null,
          'profileImage': null,
          'groupName': null,
          'role': 'other',
        };
        final identity = PeerIdentity.fromJson(json);

        expect(identity.name, isNull);
        expect(identity.profileImage, isNull);
        expect(identity.groupName, isNull);
      });
    });

    group('round-trip serialization', () {
      test('preserves all fields through json round-trip', () {
        const original = PeerIdentity(
          id: 'test-id',
          displayName: 'Test User',
          name: 'Full Name',
          profileImage: 'base64imagedata',
          groupName: 'Group A',
          role: UserRole.teacher,
        );

        final json = original.toJson();
        final restored = PeerIdentity.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.displayName, equals(original.displayName));
        expect(restored.name, equals(original.name));
        expect(restored.profileImage, equals(original.profileImage));
        expect(restored.groupName, equals(original.groupName));
        expect(restored.role, equals(original.role));
      });
    });
  });
}
