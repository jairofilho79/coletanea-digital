import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/translation_remote_datasource.dart';
import '../../data/datasources/translation_local_datasource.dart';
import '../../domain/services/translation_service.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/storage/providers.dart';
import '../../../../core/locale/locale_providers.dart';

/// Provider do datasource remoto de traduções
final translationRemoteDataSourceProvider = Provider<TranslationRemoteDataSource>((ref) {
  final client = ref.watch(coldigomClientProvider);
  return TranslationRemoteDataSource(client);
});

/// Provider do datasource local de traduções
final translationLocalDataSourceProvider = Provider<TranslationLocalDataSource>((ref) {
  return TranslationLocalDataSource();
});

/// Provider do serviço de traduções
final translationServiceProvider = Provider<TranslationService>((ref) {
  final remoteDataSource = ref.watch(translationRemoteDataSourceProvider);
  final localDataSource = ref.watch(translationLocalDataSourceProvider);
  return TranslationService(remoteDataSource, localDataSource);
});

/// Provider que carrega as traduções para o idioma atual
/// Usa o idioma detectado do sistema ou selecionado manualmente
final translationsLoadedProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(translationServiceProvider);
  final languageCode = ref.watch(currentLanguageCodeProvider);
  await service.loadTranslations(languageCode);
});
