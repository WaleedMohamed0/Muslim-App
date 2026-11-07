import 'quran_reciter.dart';

class QuranDownloadedAudio {
  const QuranDownloadedAudio({
    required this.url,
    required this.surahNumber,
    required this.reciter,
  });

  final String url;
  final int surahNumber;
  final QuranReciter reciter;
}
