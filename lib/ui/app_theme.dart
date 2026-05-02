import 'package:flutter/material.dart';

/// Палитра под KPI-DRIVE (логотип использует чёткие синий/красный/зелёный/жёлтый
/// акценты на тёмном фоне).
class KpiPalette {
  static const Color bg = Color(0xFF0E1116);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceAlt = Color(0xFF1F2630);
  static const Color border = Color(0xFF2A3039);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textMuted = Color(0xFF8B949E);

  // Акценты из логотипа
  static const Color accentBlue = Color(0xFF2F8FED);
  static const Color accentRed = Color(0xFFE5484D);
  static const Color accentGreen = Color(0xFF3FB950);
  static const Color accentYellow = Color(0xFFE3B341);

  /// Цвет колонки по индексу — циклически.
  static Color columnAccent(int i) {
    const colors = [accentBlue, accentGreen, accentYellow, accentRed];
    return colors[i % colors.length];
  }
}

ThemeData buildKpiTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: KpiPalette.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: KpiPalette.accentBlue,
      surface: KpiPalette.surface,
      onSurface: KpiPalette.textPrimary,
      error: KpiPalette.accentRed,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: KpiPalette.textPrimary,
      displayColor: KpiPalette.textPrimary,
      fontFamily: 'IBM Plex Sans',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KpiPalette.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: KpiPalette.surfaceAlt,
      contentTextStyle: TextStyle(color: KpiPalette.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
