import 'package:coletanea_digital/core/network/changelog_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangelogVersionResponse', () {
    test('fromJson parses current_version', () {
      final json = <String, dynamic>{'current_version': 42};
      final res = ChangelogVersionResponse.fromJson(json);
      expect(res.currentVersion, 42);
    });
  });

  group('ChangelogEntry', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'version': 4,
        'entity_type': 'praise',
        'entity_id': 'uuid-123',
        'action': 'updated',
        'created_at': '2025-01-01T00:00:00Z',
      };
      final entry = ChangelogEntry.fromJson(json);
      expect(entry.version, 4);
      expect(entry.entityType, 'praise');
      expect(entry.entityId, 'uuid-123');
      expect(entry.action, 'updated');
      expect(entry.createdAt, '2025-01-01T00:00:00Z');
    });
  });

  group('ChangelogResponse', () {
    test('fromJson parses current_version and changes', () {
      final json = <String, dynamic>{
        'current_version': 5,
        'changes': [
          <String, dynamic>{
            'version': 4,
            'entity_type': 'praise',
            'entity_id': 'uuid-123',
            'action': 'updated',
            'created_at': '2025-01-01T00:00:00Z',
          },
          <String, dynamic>{
            'version': 5,
            'entity_type': 'praise_tag',
            'entity_id': 'uuid-456',
            'action': 'created',
            'created_at': null,
          },
        ],
      };
      final res = ChangelogResponse.fromJson(json);
      expect(res.currentVersion, 5);
      expect(res.changes.length, 2);
      expect(res.changes[0].entityType, 'praise');
      expect(res.changes[1].entityType, 'praise_tag');
    });

    test('fromJson with empty changes', () {
      final json = <String, dynamic>{
        'current_version': 3,
        'changes': [],
      };
      final res = ChangelogResponse.fromJson(json);
      expect(res.currentVersion, 3);
      expect(res.changes, isEmpty);
    });
  });
}
