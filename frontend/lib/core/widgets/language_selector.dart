import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../locale/locale_providers.dart';
import '../locale/locale_service.dart';
import '../../features/praises/presentation/providers/translation_providers.dart';

/// Widget para seleção de idioma
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeService = ref.watch(localeServiceProvider);
    final currentLanguage = ref.watch(currentLanguageCodeProvider);
    final supportedLanguages = localeService.getSupportedLanguages();

    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Idioma'),
      subtitle: Text(_getLanguageDisplayName(currentLanguage)),
      trailing: DropdownButton<String>(
        value: currentLanguage,
        underline: const SizedBox.shrink(),
        items: supportedLanguages.map((code) {
          return DropdownMenuItem<String>(
            value: code,
            child: Text(_getLanguageDisplayName(code)),
          );
        }).toList(),
        onChanged: (String? newLanguage) async {
          if (newLanguage != null && newLanguage != currentLanguage) {
            await localeService.setLanguageCode(newLanguage);
            // Invalida as traduções para forçar recarregamento com novo idioma
            ref.invalidate(translationsLoadedProvider);
            // Força rebuild do provider de idioma
            ref.invalidate(currentLanguageCodeProvider);
          }
        },
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      default:
        return code.toUpperCase();
    }
  }
}
