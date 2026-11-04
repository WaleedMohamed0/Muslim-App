import '../entities/quran_ayah_timing.dart';
import '../entities/quran_downloaded_audio.dart';

abstract interface class QuranAudioRepository {
  Future<String?> cachedPath(String url, {String? legacyUrl});
  String urlFor(int surahNumber, {required String reciterId});
  Future<List<QuranAyahTiming>> ayahTimings({
    required int surahNumber,
    required String reciterId,
    required int readId,
  });
  Future<void> download(String url);
  Future<List<QuranDownloadedAudio>> downloadedAudios();
  Future<void> deleteDownloadedAudio(String url);
}
