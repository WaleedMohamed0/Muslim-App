import '../repositories/quran_audio_repository.dart';

class ResolveSurahAudio {
  const ResolveSurahAudio(this.repository);
  final QuranAudioRepository repository;
  Future<String?> call(int surahNumber, {required String reciterId}) {
    final url = repository.urlFor(surahNumber, reciterId: reciterId);
    return repository.cachedPath(url);
  }
}
