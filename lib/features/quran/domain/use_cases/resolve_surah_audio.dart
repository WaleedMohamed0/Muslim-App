import '../repositories/quran_audio_repository.dart';

class ResolveSurahAudio {
  const ResolveSurahAudio(this.repository);
  final QuranAudioRepository repository;
  Future<String?> call(int surahNumber) => repository.cachedPath(surahNumber);
}
