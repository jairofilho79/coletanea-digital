import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors inspired by plpcjf - Coletânea Digital
  static const Color primaryColor = Color(0xFFD4AF37); // Gold
  static const Color goldLight = Color(0xFFF4D03F); // Gold Light
  static const Color backgroundColor = Color(0xFF4B2D2B); // Marrom avermelhado escuro
  static const Color cardColor = Color(0xFFF5E6D3); // Bege mais escuro e suave (reduzido brilho)
  static const Color titleColor = Color(0xFF5A2A2A); // Marrom avermelhado mais escuro para melhor contraste
  static const Color btnBackgroundColor = Color(0xFF6A3B39); // Marrom avermelhado médio
  static const Color surfaceColor = Color(0xFF2A2A2A);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A); // Preto suave para melhor contraste
  static const Color textSecondaryColor = Color(0xFF4A4A4A); // Cinza escuro para propriedades e tags (mais escuro)
  static const Color textTertiaryColor = Color(0xFF6B6B6B); // Para ícones e elementos secundários
  static const Color placeholderColor = Color(0xFFF0E68C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: goldLight,
        surface: cardColor,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.ebGaramond(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          shadows: const [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
        shape: const Border(
          bottom: BorderSide(
            color: primaryColor,
            width: 4,
          ),
        ),
      ),
      textTheme: GoogleFonts.openSansTextTheme().copyWith(
        displayLarge: GoogleFonts.ebGaramond(
          color: primaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
        titleLarge: GoogleFonts.ebGaramond(
          color: titleColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.openSans(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500, // Peso médio para melhor legibilidade
        ),
        bodyMedium: GoogleFonts.openSans(
          color: textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600, // Mais grosso para propriedades
        ),
        bodySmall: GoogleFonts.openSans(
          color: textSecondaryColor, // Mesmo cinza escuro das propriedades
          fontSize: 12,
          fontWeight: FontWeight.w600, // Mais grosso para tags e elementos secundários
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnBackgroundColor,
          foregroundColor: Colors.white,
          side: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: goldLight,
            width: 2,
          ),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF5A5A5A), // Placeholder cinza escuro para contraste adequado com fundo bege
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF5A5A5A), // Label cinza escuro
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF5A5A5A), // Floating label cinza escuro
        ),
      ),
      buttonTheme: const ButtonThemeData(
        minWidth: 48,
        height: 48,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: goldLight,
        surface: cardColor,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.ebGaramond(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          shadows: const [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
        shape: const Border(
          bottom: BorderSide(
            color: primaryColor,
            width: 4,
          ),
        ),
      ),
      textTheme: GoogleFonts.openSansTextTheme().copyWith(
        displayLarge: GoogleFonts.ebGaramond(
          color: primaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
        titleLarge: GoogleFonts.ebGaramond(
          color: titleColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.openSans(
          color: textColor,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.openSans(
          color: textSecondaryColor,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.openSans(
          color: textSecondaryColor, // Mesmo cinza escuro das propriedades
          fontSize: 12,
          fontWeight: FontWeight.w600, // Mais grosso
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnBackgroundColor,
          foregroundColor: Colors.white,
          side: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: goldLight,
            width: 2,
          ),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF5A5A5A), // Placeholder cinza escuro para contraste adequado com fundo bege
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF5A5A5A), // Label cinza escuro
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF5A5A5A), // Floating label cinza escuro
        ),
      ),
      buttonTheme: const ButtonThemeData(
        minWidth: 48,
        height: 48,
      ),
    );
  }
}
