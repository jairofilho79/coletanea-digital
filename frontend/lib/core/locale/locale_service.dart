import 'dart:io';
import '../storage/hive_service.dart';

/// Serviço para gerenciar idioma do app
class LocaleService {
  static const String _languageCodeKey = 'selected_language_code';
  static const List<String> supportedLanguages = ['pt', 'en'];
  static const String defaultLanguage = 'pt';

  /// Obtém o código do idioma atual
  /// Prioridade: 1) Idioma salvo no settingsBox, 2) Idioma do sistema, 3) Fallback 'pt'
  String getCurrentLanguageCode() {
    // Verifica se há idioma salvo
    final savedLanguage = HiveService.settingsBox.get(_languageCodeKey) as String?;
    if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
      return savedLanguage;
    }

    // Tenta detectar idioma do sistema
    try {
      final systemLocale = Platform.localeName;
      final languageCode = _extractLanguageCode(systemLocale);
      if (supportedLanguages.contains(languageCode)) {
        return languageCode;
      }
    } catch (e) {
      // Se falhar, usa fallback
    }

    return defaultLanguage;
  }

  /// Extrai código de idioma de um locale (ex: 'pt_BR' -> 'pt', 'en_US' -> 'en')
  String _extractLanguageCode(String locale) {
    final parts = locale.split('_');
    return parts.isNotEmpty ? parts[0].toLowerCase() : defaultLanguage;
  }

  /// Define o código do idioma selecionado manualmente
  Future<void> setLanguageCode(String code) async {
    if (!supportedLanguages.contains(code)) {
      throw ArgumentError('Idioma não suportado: $code');
    }
    await HiveService.settingsBox.put(_languageCodeKey, code);
  }

  /// Obtém lista de idiomas suportados
  List<String> getSupportedLanguages() => List.unmodifiable(supportedLanguages);
}
