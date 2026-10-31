abstract interface class QuranAudioRepository {
  Future<String?> cachedPath(int surahNumber);
  String urlFor(int surahNumber);
  Future<void> download(String url);
}
