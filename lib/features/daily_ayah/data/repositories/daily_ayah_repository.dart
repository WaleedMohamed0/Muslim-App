import 'package:muslim/features/daily_ayah/domain/entities/daily_ayah.dart';
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';
import 'package:quran/quran.dart' as quran;

/// Resolves one globally consistent ayah per UTC day from a fixed shuffled
/// permutation. The permutation changes only when the selection pool changes.
class DailyAyahRepository {
  static const _poolSize = 6236;
  static final _epoch = DateTime.utc(2024, 1, 1);
  static List<(int, int)>? _sequence;

  Future<DailyAyah> getForDate(DateTime date) async {
    await UthmaniQuranText.initialize();
    final sequence = _sequence ??= _shuffledSequence();
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    final day = utcDate.difference(_epoch).inDays;
    final (surah, ayah) = sequence[((day % _poolSize) + _poolSize) % _poolSize];
    return DailyAyah(
      surahNumber: surah,
      ayahNumber: ayah,
      text: UthmaniQuranText.getVerse(surah, ayah),
      surahName: UthmaniQuranText.getSurahName(surah),
    );
  }

  List<(int, int)> _shuffledSequence() {
    final items = <(int, int)>[];
    for (var surah = 1; surah <= 114; surah++) {
      for (var ayah = 1; ayah <= quran.getVerseCount(surah); ayah++) {
        items.add((surah, ayah));
      }
    }
    var state = 0x6D2B79F5;
    int next() {
      state = (state + 0x6D2B79F5) & 0xffffffff;
      var value = state;
      value = ((value ^ (value >> 15)) * (value | 1)) & 0xffffffff;
      value ^= value + (((value ^ (value >> 7)) * (value | 61)) & 0xffffffff);
      return (value ^ (value >> 14)) & 0xffffffff;
    }
    for (var index = items.length - 1; index > 0; index--) {
      final swapIndex = next() % (index + 1);
      final value = items[index];
      items[index] = items[swapIndex];
      items[swapIndex] = value;
    }
    return items;
  }
}
