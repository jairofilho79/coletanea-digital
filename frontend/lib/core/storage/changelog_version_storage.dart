import 'hive_service.dart';

const String _changelogVersionKey = 'changelog_version';

/// Persistência da versão local do changelog (sync com coldigom).
/// Usa [HiveService.metadataBox]; ausência de valor indica sync inicial (since_version=0).
abstract final class ChangelogVersionStorage {
  static int? getChangelogVersion() {
    final raw = HiveService.metadataBox.get(_changelogVersionKey);
    if (raw == null) return null;
    if (raw is int) return raw;
    final asNum = num.tryParse(raw.toString());
    return asNum?.toInt();
  }

  static Future<void> setChangelogVersion(int version) async {
    await HiveService.metadataBox.put(_changelogVersionKey, version);
  }
}
