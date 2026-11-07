import 'package:flutter/material.dart';

class QuranReaderBackgroundPreset {
  const QuranReaderBackgroundPreset({
    required this.name,
    required this.color,
  });

  final String name;
  final Color color;
}

abstract final class QuranReaderBackgroundColors {
  static const lightDefault = Color(0xFFEBF0EB);
  static const darkDefault = Color(0xFF171D19);
  static const lightText = Color(0xFF26372F);
  static const darkText = Color(0xFFE8EEE9);
  static const lightAccent = Color(0xFF315C4C);
  static const darkAccent = Color(0xFFA5C2B1);

  static const light = <QuranReaderBackgroundPreset>[
    QuranReaderBackgroundPreset(name: 'أخضر هادئ', color: lightDefault),
    QuranReaderBackgroundPreset(name: 'ورق كريمي', color: Color(0xFFF8F3E7)),
    QuranReaderBackgroundPreset(name: 'عاجي دافئ', color: Color(0xFFF2EBDD)),
    QuranReaderBackgroundPreset(name: 'أخضر فاتح', color: Color(0xFFE3EEE5)),
    QuranReaderBackgroundPreset(name: 'أزرق هادئ', color: Color(0xFFE5EDF1)),
    QuranReaderBackgroundPreset(name: 'وردي باهت', color: Color(0xFFF2E7E5)),
  ];

  static const dark = <QuranReaderBackgroundPreset>[
    QuranReaderBackgroundPreset(name: 'أخضر ليلي', color: darkDefault),
    QuranReaderBackgroundPreset(name: 'فحمي بارد', color: Color(0xFF1C2428)),
    QuranReaderBackgroundPreset(name: 'بني داكن', color: Color(0xFF29231E)),
    QuranReaderBackgroundPreset(name: 'أخضر داكن', color: Color(0xFF202923)),
    QuranReaderBackgroundPreset(name: 'بنفسجي داكن', color: Color(0xFF26212B)),
    QuranReaderBackgroundPreset(name: 'رمادي ليلي', color: Color(0xFF24272A)),
  ];

  static Color defaultFor(bool darkMode) =>
      darkMode ? darkDefault : lightDefault;

  static Color textFor(bool darkMode) => darkMode ? darkText : lightText;

  static Color accentFor(bool darkMode) => darkMode ? darkAccent : lightAccent;

  static List<QuranReaderBackgroundPreset> presetsFor(bool darkMode) =>
      darkMode ? dark : light;
}
