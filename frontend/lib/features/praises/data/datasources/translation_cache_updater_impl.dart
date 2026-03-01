import '../../../../core/storage/translation_cache_updater.dart';
import 'translation_local_datasource.dart';

/// Implementação de [TranslationCacheUpdater] que delega para [TranslationLocalDataSource].
class TranslationCacheUpdaterImpl implements TranslationCacheUpdater {
  TranslationCacheUpdaterImpl(this._local);

  final TranslationLocalDataSource _local;

  @override
  Future<void> mergeTranslationEntry(
    String languageCode,
    String type,
    String entityId,
    String translatedName,
  ) async {
    await _local.mergeTranslationEntry(
      languageCode,
      type,
      entityId,
      translatedName,
    );
  }

  @override
  Future<void> removeTranslationEntryForEntity(String type, String entityId) async {
    await _local.removeTranslationEntryForEntity(type, entityId);
  }
}
