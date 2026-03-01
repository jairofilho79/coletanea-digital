import 'package:coletanea_digital/core/network/changelog_api.dart';
import 'package:coletanea_digital/core/storage/metadata_revalidation_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetadataRevalidationRunner.deduplicateByEntity', () {
    test('keeps single entry per entity_type+entity_id with highest version', () {
      final changes = [
        ChangelogEntry(
          version: 10,
          entityType: 'praise',
          entityId: 'id-a',
          action: 'updated',
        ),
        ChangelogEntry(
          version: 15,
          entityType: 'praise',
          entityId: 'id-a',
          action: 'updated',
        ),
        ChangelogEntry(
          version: 12,
          entityType: 'praise',
          entityId: 'id-a',
          action: 'updated',
        ),
      ];
      final result = MetadataRevalidationRunner.deduplicateByEntity(changes);
      expect(result.length, 1);
      expect(result.single.version, 15);
      expect(result.single.entityId, 'id-a');
    });

    test('keeps one entry per distinct entity', () {
      final changes = [
        ChangelogEntry(
          version: 1,
          entityType: 'praise',
          entityId: 'id-1',
          action: 'created',
        ),
        ChangelogEntry(
          version: 2,
          entityType: 'praise_tag',
          entityId: 'id-2',
          action: 'created',
        ),
        ChangelogEntry(
          version: 3,
          entityType: 'praise',
          entityId: 'id-1',
          action: 'updated',
        ),
      ];
      final result = MetadataRevalidationRunner.deduplicateByEntity(changes);
      expect(result.length, 2);
      final byKey = {for (final e in result) '${e.entityType}:${e.entityId}': e};
      expect(byKey['praise:id-1']!.version, 3);
      expect(byKey['praise_tag:id-2']!.version, 2);
    });

    test('empty list returns empty', () {
      final result = MetadataRevalidationRunner.deduplicateByEntity([]);
      expect(result, isEmpty);
    });
  });
}
