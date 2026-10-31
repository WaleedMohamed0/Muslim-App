import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/repositories/quran_audio_repository.dart' as contract;

class QuranAudioRepository implements contract.QuranAudioRepository {
  @override
  Future<String?> cachedPath(int surahNumber) async => (await DefaultCacheManager().getFileFromCache(urlFor(surahNumber)))?.file.path;

  @override
  String urlFor(int surahNumber) => '${AppColors.quranSoundUrl}$surahNumber.mp3';

  @override
  Future<void> download(String url) async { await DefaultCacheManager().downloadFile(url); }
}
