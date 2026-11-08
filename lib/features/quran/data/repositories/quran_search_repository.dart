import 'package:quran/quran.dart' as quran;
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';
import 'package:muslim/features/quran/domain/entities/quran_search_result.dart';

class QuranSearchRepository {
  Future<List<QuranSearchResult>> search(String query) async {
    await UthmaniQuranText.initialize();
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.isEmpty) return const [];

    final results = <QuranSearchResult>[];
    for (var surah = 1; surah <= quran.totalSurahCount; surah++) {
      for (var ayah = 1; ayah <= quran.getVerseCount(surah); ayah++) {
        final text = UthmaniQuranText.getVerse(surah, ayah);
        if (normalizeArabic(text).contains(normalizedQuery)) {
          results.add(QuranSearchResult(
            surahNumber: surah,
            ayahNumber: ayah,
            text: text,
            surahName: UthmaniQuranText.getSurahName(surah),
            juzNumber: quran.getJuzNumber(surah, ayah),
          ));
        }
      }
    }
    return results;
  }

  static String normalizeArabic(String value) {
    final withoutMarks = value.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    return withoutMarks
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
