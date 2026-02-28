import 'package:flutter/material.dart';

/// Widget que cria o efeito "light-beam" dourado abaixo de botões ativos
/// Inspirado no estilo do PLPCJF
class LightBeam extends StatelessWidget {
  final bool isActive;
  final double? width;
  final double height;

  const LightBeam({
    super.key,
    this.isActive = false,
    this.width,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: -2,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: height,
        width: isActive ? (width ?? double.infinity) : 0,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Colors.transparent,
              Color(0xFFFFF0A0), // rgba(255, 240, 160, 0.95)
              Color(0xFFFFE678), // rgba(255, 230, 120, 1)
              Color(0xFFFFDC64), // rgba(255, 220, 100, 1)
              Color(0xFFFFE678), // rgba(255, 230, 120, 1)
              Color(0xFFFFF0A0), // rgba(255, 240, 160, 0.95)
              Colors.transparent,
            ],
            stops: [0.0, 0.15, 0.30, 0.50, 0.70, 0.85, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFDC64).withOpacity(1),
              blurRadius: 12,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFFFFDC64).withOpacity(0.8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFFFFDC64).withOpacity(0.6),
              blurRadius: 36,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFFFFDC64).withOpacity(0.4),
              blurRadius: 48,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFFFFDC64).withOpacity(0.7),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
