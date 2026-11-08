import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/features/quran/data/repositories/quran_audio_repository.dart';

void main() {
  group('QuranAudioRepository.normalizeTimingRecords', () {
    test('ignores Saud opening Bismillah and preserves numbered ayahs', () {
      final timings = QuranAudioRepository.normalizeTimingRecords([
        {'ayah': 0, 'start_time': 0},
        {'ayah': 1, 'start_time': 2552},
        {'ayah': 2, 'start_time': 9354},
        {'ayah': 6, 'start_time': 43210},
      ], reciterId: 'mp3quran_31', surahNumber: 2);

      expect(timings.map((timing) => timing.ayah), [1, 2, 6]);
      expect(timings.first.start.inMilliseconds, 2552);
      expect(timings.last.start.inMilliseconds, 43210);
    });

    test('keeps Al-Fatihah verse numbering unchanged', () {
      final timings = QuranAudioRepository.normalizeTimingRecords([
        {'ayah': 0, 'start_time': 0},
        {'ayah': 1, 'start_time': 6420},
        {'ayah': 2, 'start_time': 11120},
        {'ayah': 7, 'start_time': 38960},
      ], reciterId: 'mp3quran_31', surahNumber: 1);

      expect(timings.map((timing) => timing.ayah), [1, 2, 7]);
      expect(timings.first.start.inMilliseconds, 6420);
      expect(timings.last.start.inMilliseconds, 38960);
    });

    test('preserves other reciters numbering', () {
      final timings = QuranAudioRepository.normalizeTimingRecords([
        {'ayah': 0, 'start_time': 0},
        {'ayah': 1, 'start_time': 6420},
        {'ayah': 2, 'start_time': 11120},
      ], reciterId: 'other', surahNumber: 2);

      expect(timings.map((timing) => timing.ayah), [1, 2]);
      expect(timings.first.start.inMilliseconds, 6420);
    });
  });
}
