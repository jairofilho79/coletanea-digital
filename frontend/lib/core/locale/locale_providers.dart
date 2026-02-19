import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locale_service.dart';

/// Provider do LocaleService
final localeServiceProvider = Provider<LocaleService>((ref) {
  return LocaleService();
});

/// Provider que retorna o código do idioma atual
final currentLanguageCodeProvider = Provider<String>((ref) {
  final localeService = ref.watch(localeServiceProvider);
  return localeService.getCurrentLanguageCode();
});
