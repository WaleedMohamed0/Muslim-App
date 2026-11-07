import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

/// Local, verified text data used by the Mushaf reader.
///
/// Verse text is bundled from verified Uthmani sources. The data file records
/// provenance for each source segment; preserve its source and license notes.
abstract final class UthmaniQuranText {
  static Map<int, Map<int, String>>? _verses;
  static Map<int, String>? _surahNames;

  static Future<void> initialize() async {
    if (_verses != null && _surahNames != null) return;

    final source = await rootBundle.loadString(
      'assets/features/quran/data/quran-uthmani-hafs.txt',
    );
    final verses = <int, Map<int, String>>{};
    for (final rawLine in source.split('\n')) {
      final line = rawLine.trimRight();
      final firstSeparator = line.indexOf('|');
      if (firstSeparator < 0) continue;
      final secondSeparator = line.indexOf('|', firstSeparator + 1);
      if (secondSeparator < 0) continue;
      final surah = int.tryParse(line.substring(0, firstSeparator));
      final ayah = int.tryParse(
        line.substring(firstSeparator + 1, secondSeparator),
      );
      if (surah == null || ayah == null) continue;
      verses.putIfAbsent(surah, () => <int, String>{})[ayah] =
          line.substring(secondSeparator + 1);
    }

    if (verses.length != 114 ||
        verses.values.fold<int>(0, (sum, items) => sum + items.length) != 6236) {
      throw StateError('Bundled Uthmani Quran text failed validation.');
    }
    for (var surah = 1; surah <= 114; surah++) {
      final ayahs = verses[surah];
      if (ayahs == null || ayahs.length != quran.getVerseCount(surah)) {
        throw StateError('Invalid verse count in bundled Surah $surah.');
      }
      for (var ayah = 1; ayah <= ayahs.length; ayah++) {
        if (!ayahs.containsKey(ayah)) {
          throw StateError('Missing bundled Quran verse $surah:$ayah.');
        }
      }
    }

    final namesSource = await rootBundle.loadString(
      'assets/features/quran/data/surah-names-ar.txt',
    );
    final names = <int, String>{};
    for (final rawLine in namesSource.split('\n')) {
      final line = rawLine.trim();
      final separator = line.indexOf('|');
      if (separator < 0) continue;
      final number = int.tryParse(line.substring(0, separator));
      if (number != null) names[number] = line.substring(separator + 1);
    }
    if (names.length != 114 ||
        List<int>.generate(114, (index) => index + 1)
            .any((number) => !names.containsKey(number))) {
      throw StateError('Bundled Arabic Surah names failed validation.');
    }

    _verses = verses;
    _surahNames = names;
  }

  static String getVerse(int surahNumber, int verseNumber) {
    final verse = _verses?[surahNumber]?[verseNumber];
    if (verse == null) {
      throw StateError(
        'Uthmani Quran text is not available for $surahNumber:$verseNumber.',
      );
    }
    return verse;
  }

  static String getSurahName(int surahNumber) {
    final name = _surahNames?[surahNumber];
    if (name == null) {
      throw StateError('Arabic Surah name is not available for $surahNumber.');
    }
    return name;
  }
}
