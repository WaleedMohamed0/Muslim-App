import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all bundled Tanzil verses load verbatim across all surahs', () async {
    await UthmaniQuranText.initialize();
    final source = await rootBundle.loadString(
      'assets/features/quran/data/tanzil-uthmani-1.1.txt',
    );
    var verseCount = 0;

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

      final text = line.substring(secondSeparator + 1);
      expect(
        UthmaniQuranText.getVerse(surah, ayah),
        text,
        reason: 'Runtime text changed Tanzil verse $surah:$ayah.',
      );
      verseCount++;
    }

    expect(verseCount, 6236);
    for (var surah = 1; surah <= 114; surah++) {
      final expectedVerses = quran.getVerseCount(surah);
      for (var ayah = 1; ayah <= expectedVerses; ayah++) {
        expect(UthmaniQuranText.getVerse(surah, ayah), isNotEmpty);
      }
    }
  });
}
