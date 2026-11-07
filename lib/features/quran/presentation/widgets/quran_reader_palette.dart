import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'quran_reader_background_colors.dart';

class QuranReaderPalette {
  const QuranReaderPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.highlight,
    required this.activeAyahHighlight,
    required this.bookmarkHighlight,
    required this.bookmarkBorder,
    required this.frame,
    required this.ornament,
    required this.metadata,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color accent;
  final Color highlight;
  final Color activeAyahHighlight;
  final Color bookmarkHighlight;
  final Color bookmarkBorder;
  final Color frame;
  final Color ornament;
  final Color metadata;

  static QuranReaderPalette fromTheme(BuildContext context) {
    final appTheme = Theme.of(context);
    final appColors = appTheme.colorScheme;
    final isDark = appTheme.brightness == Brightness.dark;
    final cubit = context.read<QuranCubit>();
    const nightPaper = Color(0xFF171D19);
    const nightFrame = Color(0xFF222B26);
    final savedBackground = isDark
        ? cubit.darkReaderBackgroundColorValue
        : cubit.lightReaderBackgroundColorValue;
    final background = savedBackground != null
        ? Color(savedBackground)
        : isDark
            ? nightPaper
            : QuranReaderBackgroundColors.defaultFor(false);
    final backgroundHsl = HSLColor.fromColor(background);
    final sourceHue = backgroundHsl.saturation < .08
        ? 151.0
        : backgroundHsl.hue;
    final darkInk = const Color(0xFF1D2922);
    final lightInk = const Color(0xFFE8EEE9);
    final useDarkInk = _contrastRatio(darkInk, background) >=
        _contrastRatio(lightInk, background);
    final accentHue = (sourceHue + 24) % 360;
    final ornamentHue = (sourceHue + 48) % 360;
    final accentSaturation =
        (backgroundHsl.saturation * .55 + .2).clamp(.28, .52).toDouble();
    final accent = _harmonizedForeground(
      background: background,
      hue: accentHue,
      saturation: accentSaturation,
      preferredLightness: useDarkInk ? .30 : .78,
      minimumContrast: 4.5,
    );
    final ornament = _harmonizedForeground(
      background: background,
      hue: ornamentHue,
      saturation:
          (backgroundHsl.saturation * .42 + .18).clamp(.24, .44).toDouble(),
      preferredLightness: useDarkInk ? .40 : .68,
      minimumContrast: 3,
    );
    final text = useDarkInk ? darkInk : lightInk;
    final muted = _harmonizedForeground(
      background: background,
      hue: sourceHue,
      saturation: .12,
      preferredLightness: useDarkInk ? .42 : .72,
      minimumContrast: 3,
    );
    final frame = Color.alphaBlend(
      ornament.withValues(alpha: useDarkInk ? .42 : .52),
      background,
    );
    final highlight = Color.alphaBlend(
      accent.withValues(alpha: useDarkInk ? .10 : .22),
      background,
    );
    final activeAyahHighlight = Color.alphaBlend(
      accent.withValues(
        alpha: isDark ? (useDarkInk ? .10 : .22) : .65,
      ),
      background,
    );
    final bookmarkHighlight = Color.alphaBlend(
      ornament.withValues(alpha: useDarkInk ? .18 : .15),
      background,
    );
    return QuranReaderPalette(
      background: background,
      surface: isDark ? nightFrame : appColors.surface,
      text: text,
      muted: muted,
      accent: accent,
      highlight: highlight,
      activeAyahHighlight: activeAyahHighlight,
      bookmarkHighlight: bookmarkHighlight,
      bookmarkBorder: ornament,
      frame: frame,
      ornament: ornament,
      metadata: accent,
    );
  }

  static double _contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + .05) / (darker + .05);
  }

  static Color _harmonizedForeground({
    required Color background,
    required double hue,
    required double saturation,
    required double preferredLightness,
    required double minimumContrast,
  }) {
    const lightnessCandidates = [
      .18,
      .22,
      .26,
      .30,
      .34,
      .38,
      .42,
      .58,
      .62,
      .66,
      .70,
      .74,
      .78,
      .82,
      .86,
      .90,
    ];
    Color? closestContrastingColor;
    var closestDistance = double.infinity;
    var strongestColor = HSLColor.fromAHSL(
      1,
      hue,
      saturation,
      preferredLightness,
    ).toColor();
    var strongestContrast = 0.0;

    for (final lightness in lightnessCandidates) {
      final candidate = HSLColor.fromAHSL(
        1,
        hue,
        saturation,
        lightness,
      ).toColor();
      final contrast = _contrastRatio(candidate, background);
      if (contrast > strongestContrast) {
        strongestColor = candidate;
        strongestContrast = contrast;
      }
      if (contrast < minimumContrast) continue;
      final distance = (lightness - preferredLightness).abs();
      if (distance < closestDistance) {
        closestContrastingColor = candidate;
        closestDistance = distance;
      }
    }
    return closestContrastingColor ?? strongestColor;
  }
}


