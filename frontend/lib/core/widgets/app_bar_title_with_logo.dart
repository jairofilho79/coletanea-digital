import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Título de AppBar padronizado com a logo LOGO_ONLY_GOLD_DARK ao lado.
/// Usado em todas as páginas para manter identidade visual consistente.
class AppBarTitleWithLogo extends StatelessWidget {
  /// O título exibido ao lado da logo. Pode ser [Text] ou outro widget.
  final Widget title;

  const AppBarTitleWithLogo({
    super.key,
    required this.title,
  });

  /// Construtor de conveniência para título como String.
  factory AppBarTitleWithLogo.text(String text) {
    return AppBarTitleWithLogo(
      title: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/logo/LOGO_ONLY_GOLD_DARK.svg',
          height: 24,
          fit: BoxFit.contain,
          semanticsLabel: 'Coletânea Digital Logo',
          allowDrawingOutsideViewBox: true,
        ),
        const SizedBox(width: 8),
        title,
      ],
    );
  }
}
