/// Interface para atualizar o cache de traduções a partir do changelog.
/// A implementação pode vir do layer de features (ex.: TranslationLocalDataSource).
abstract class TranslationCacheUpdater {
  Future<void> mergeTranslationEntry(
    String languageCode,
    String type,
    String entityId,
    String translatedName,
  );

  Future<void> removeTranslationEntryForEntity(String type, String entityId);
}
