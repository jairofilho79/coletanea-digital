import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget reutilizável para exibir a logo da Coletânea Digital
/// 
/// Por padrão usa a logo colorida. Para fundos escuros, use [useWhiteLogo: true]
/// Se [height] for null, usa toda a altura disponível do contexto (útil para AppBar)
class AppLogo extends StatefulWidget {
  final double? height;
  final bool useWhiteLogo;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.height,
    this.useWhiteLogo = false,
    this.fit = BoxFit.contain,
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final logoPath = widget.useWhiteLogo
        ? 'assets/logo/LOGO_BRANCO.svg'
        : 'assets/logo/LOGO_COLORIDO_INLINE_GOLD_LIGHT.svg';

    // Se height não foi especificado, usa toda a altura disponível com um pouco de padding
    final effectiveHeight = widget.height ?? 
        (MediaQuery.of(context).size.height * 0.06).clamp(40.0, 56.0);

    if (_hasError) {
      return _buildFallback(context, effectiveHeight);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Usa toda a altura disponível do contexto pai (AppBar)
        final availableHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight - 8 // Deixa um pouco de padding
            : effectiveHeight;

        return SvgPicture.asset(
          logoPath,
          height: availableHeight,
          fit: widget.fit,
          placeholderBuilder: (context) => SizedBox(
            height: availableHeight,
            width: availableHeight * 3, // Proporção aproximada da logo
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          colorFilter: widget.useWhiteLogo
              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
              : null,
          semanticsLabel: 'Coletânea Digital Logo',
          allowDrawingOutsideViewBox: true,
          // Tratamento de erro mais robusto
          errorBuilder: (context, error, stackTrace) {
            // Marca o erro e reconstrói com fallback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasError) {
                setState(() {
                  _hasError = true;
                });
              }
            });
            return _buildFallback(context, availableHeight);
          },
        );
      },
    );
  }

  Widget _buildFallback(BuildContext context, double height) {
    // Fallback: mostra texto estilizado se o SVG não carregar
    return Text(
      'Coletânea Digital',
      style: TextStyle(
        fontFamily: 'EB Garamond',
        fontSize: height * 0.7,
        fontWeight: FontWeight.bold,
        color: widget.useWhiteLogo
            ? Colors.white
            : Theme.of(context).colorScheme.primary,
        shadows: const [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 2,
            color: Colors.black26,
          ),
        ],
      ),
    );
  }
}
