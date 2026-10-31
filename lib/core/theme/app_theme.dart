import 'package:flutter/material.dart';

class AppTheme {
  static const _green = Color(0xFF176B5B);
  static const _paper = Color(0xFFF7F6F0);

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        seed: _green,
        background: _paper,
        surface: Colors.white,
        ink: const Color(0xFF1B302B),
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        seed: const Color(0xFF6FC6A9),
        background: const Color(0xFF111B18),
        surface: const Color(0xFF1B2823),
        ink: const Color(0xFFE8F2ED),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color seed,
    required Color background,
    required Color surface,
    required Color ink,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: background,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: ink),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .4)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        titleTextStyle: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w600),
        subtitleTextStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .55), thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
      ),
      textTheme: Typography.material2021(platform: TargetPlatform.android).black.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
    );
  }
}
