import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Os 4 perfis de interface do ReadQuest, cada um pensado para
/// um público diferente, com diferenças reais de cor, fonte e escala.
enum AppThemePreset {
  crianca,
  adolescente,
  adulto,
  idoso;

  String get label {
    switch (this) {
      case AppThemePreset.crianca:
        return 'Criança';
      case AppThemePreset.adolescente:
        return 'Adolescente';
      case AppThemePreset.adulto:
        return 'Adulto';
      case AppThemePreset.idoso:
        return 'Idoso';
    }
  }

  String get description {
    switch (this) {
      case AppThemePreset.crianca:
        return 'Cores vivas, fonte grande e arredondada';
      case AppThemePreset.adolescente:
        return 'Visual moderno e vibrante';
      case AppThemePreset.adulto:
        return 'Design limpo e equilibrado';
      case AppThemePreset.idoso:
        return 'Alto contraste e textos ampliados';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemePreset.crianca:
        return Icons.child_care_rounded;
      case AppThemePreset.adolescente:
        return Icons.emoji_emotions_rounded;
      case AppThemePreset.adulto:
        return Icons.menu_book_rounded;
      case AppThemePreset.idoso:
        return Icons.visibility_rounded;
    }
  }

  /// Multiplicador aplicado sobre o tamanho-base das fontes,
  /// além do que já vem da própria TextTheme escolhida.
  double get fontScale {
    switch (this) {
      case AppThemePreset.crianca:
        return 1.15;
      case AppThemePreset.adolescente:
        return 1.0;
      case AppThemePreset.adulto:
        return 1.0;
      case AppThemePreset.idoso:
        return 1.3;
    }
  }

  ThemeData buildThemeData() {
    switch (this) {
      case AppThemePreset.crianca:
        return _buildTheme(
          seedColor: const Color(0xFFFF9800), // laranja vibrante
          textTheme: GoogleFonts.baloo2TextTheme(),
          buttonRadius: 24,
        );
      case AppThemePreset.adolescente:
        return _buildTheme(
          seedColor: const Color(0xFF7C4DFF), // roxo vibrante
          textTheme: GoogleFonts.poppinsTextTheme(),
          buttonRadius: 16,
        );
      case AppThemePreset.adulto:
        return _buildTheme(
          seedColor: const Color(0xFF2E7D32), // verde
          textTheme: GoogleFonts.interTextTheme(),
          buttonRadius: 10,
        );
      case AppThemePreset.idoso:
        return _buildTheme(
          seedColor: const Color(0xFF0D47A1), // azul de alto contraste
          textTheme: GoogleFonts.atkinsonHyperlegibleTextTheme(),
          buttonRadius: 8,
          highContrast: true,
        );
    }
  }

  ThemeData _buildTheme({
    required Color seedColor,
    required TextTheme textTheme,
    required double buttonRadius,
    bool highContrast = false,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      contrastLevel: highContrast ? 1.0 : 0.0,
    );

    final scaledTextTheme = textTheme.apply(
      fontSizeFactor: fontScale,
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: scaledTextTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
    );
  }
}
