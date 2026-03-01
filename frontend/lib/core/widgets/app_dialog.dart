import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Tipo semântico do dialog — define ícone e cor de destaque.
enum AppDialogType { success, error, warning, info }

/// Configuração de um campo de texto para [AppDialog.input].
class AppDialogField {
  final String key;
  final String? hint;
  final String? label;
  final String? initialValue;
  final int maxLines;
  final bool autofocus;

  const AppDialogField({
    required this.key,
    this.hint,
    this.label,
    this.initialValue,
    this.maxLines = 1,
    this.autofocus = false,
  });
}

/// Dialog padronizado da aplicação.
///
/// Centraliza a estilização (fundo marrom, bordas douradas, título EB Garamond)
/// e expõe métodos estáticos para os casos de uso mais comuns.
class AppDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget> actions;
  final AppDialogType? type;
  final bool barrierDismissible;

  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.type,
    this.barrierDismissible = true,
  });

  // ---------------------------------------------------------------------------
  // Estilo base
  // ---------------------------------------------------------------------------

  static ShapeDecoration get _shape => ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
      );

  static TextStyle get _titleStyle => GoogleFonts.ebGaramond(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
      );

  // ---------------------------------------------------------------------------
  // Helpers de ícone por tipo
  // ---------------------------------------------------------------------------

  static IconData _iconForType(AppDialogType type) {
    switch (type) {
      case AppDialogType.success:
        return Icons.check_circle_outline;
      case AppDialogType.error:
        return Icons.error_outline;
      case AppDialogType.warning:
        return Icons.warning_amber_rounded;
      case AppDialogType.info:
        return Icons.info_outline;
    }
  }

  static Color _colorForType(AppDialogType type) {
    switch (type) {
      case AppDialogType.success:
        return Colors.green;
      case AppDialogType.error:
        return Colors.red;
      case AppDialogType.warning:
        return Colors.amber;
      case AppDialogType.info:
        return Colors.blue;
    }
  }

  // ---------------------------------------------------------------------------
  // Botões padronizados
  // ---------------------------------------------------------------------------

  /// Botão de cancelar (TextButton dourado).
  static Widget cancelButton(BuildContext context, {String label = 'Cancelar'}) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: Text(label, style: const TextStyle(color: AppTheme.primaryColor)),
    );
  }

  /// Botão de ação principal.
  static Widget actionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    if (isDestructive) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  // ---------------------------------------------------------------------------
  // Métodos estáticos de conveniência
  // ---------------------------------------------------------------------------

  /// Dialog genérico — aceita conteúdo e ações customizados.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? content,
    List<Widget> actions = const [],
    AppDialogType? type,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppDialog(
        title: title,
        content: content,
        actions: actions,
        type: type,
      ),
    );
  }

  /// Dialog de confirmação — retorna `true` se confirmado, `false`/`null` caso contrário.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        content: Text(message, style: const TextStyle(color: AppTheme.textColor)),
        actions: [
          cancelButton(ctx, label: cancelLabel),
          actionButton(
            ctx,
            label: confirmLabel,
            isDestructive: isDestructive,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Dialog de alerta (apenas informativo) com botão OK.
  static Future<void> alert({
    required BuildContext context,
    required String title,
    required String message,
    String okLabel = 'OK',
    AppDialogType? type,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        type: type,
        content: Text(message, style: const TextStyle(color: AppTheme.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(okLabel, style: const TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  /// Dialog com campos de texto — retorna `Map<key, value>` ou `null` se cancelado.
  static Future<Map<String, String>?> input({
    required BuildContext context,
    required String title,
    required List<AppDialogField> fields,
    String confirmLabel = 'Criar',
    String cancelLabel = 'Cancelar',
  }) {
    final controllers = <String, TextEditingController>{};
    for (final field in fields) {
      controllers[field.key] = TextEditingController(text: field.initialValue ?? '');
    }

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              TextField(
                controller: controllers[fields[i].key],
                style: const TextStyle(color: AppTheme.textDark),
                autofocus: fields[i].autofocus,
                maxLines: fields[i].maxLines,
                decoration: InputDecoration(
                  hintText: fields[i].hint,
                  labelText: fields[i].label,
                ),
              ),
            ],
          ],
        ),
        actions: [
          cancelButton(ctx),
          actionButton(
            ctx,
            label: confirmLabel,
            onPressed: () {
              final first = fields.first.key;
              if (controllers[first]!.text.trim().isEmpty) return;
              final result = <String, String>{};
              for (final entry in controllers.entries) {
                result[entry.key] = entry.value.text;
              }
              Navigator.of(ctx).pop(result);
            },
          ),
        ],
      ),
    );
  }

  /// Dialog de progresso (não-dismissível).
  static Future<T?> progress<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget> actions = const [],
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: title,
        content: content,
        actions: actions,
        barrierDismissible: false,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget? titleWidget;
    if (title != null) {
      if (type != null) {
        titleWidget = Row(
          children: [
            Icon(_iconForType(type!), color: _colorForType(type!), size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(title!, style: _titleStyle)),
          ],
        );
      } else {
        titleWidget = Text(title!, style: _titleStyle);
      }
    }

    return AlertDialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      title: titleWidget,
      content: content,
      actions: actions,
    );
  }
}
