import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quran_ayah_timing.dart';
import '../../domain/entities/quran_downloaded_audio.dart';
import '../../domain/entities/quran_reciter.dart';
import '../../domain/repositories/quran_audio_repository.dart' as contract;

class QuranAudioRepository implements contract.QuranAudioRepository {
  static const _downloadedUrlsKey = 'quran_downloaded_audio_urls';
  QuranAudioRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<String?> cachedPath(String url, {String? legacyUrl}) async {
    final cache = DefaultCacheManager();
    final cached = await cache.getFileFromCache(url);
    if (cached != null) return cached.file.path;
    if (legacyUrl == null) return null;
    return (await cache.getFileFromCache(legacyUrl))?.file.path;
  }

  @override
  String urlFor(int surahNumber, {required String reciterId}) =>
      QuranReciter.byId(reciterId).surahUrl(surahNumber);

  @override
  Future<List<QuranAyahTiming>> ayahTimings({
    required int surahNumber,
    required String reciterId,
    required int readId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'quran_ayah_timing_${reciterId}_$surahNumber';
    final saved = prefs.getString(cacheKey);
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        return decoded
            .map((item) => QuranAyahTiming(
                  ayah: item['ayah'] as int,
                  start: Duration(milliseconds: item['start'] as int),
                ))
            .toList(growable: false);
      } catch (_) {
        await prefs.remove(cacheKey);
      }
    }

    final response = await _dio.get<List<dynamic>>(
      'https://www.mp3quran.net/api/v3/ayat_timing',
      queryParameters: {'surah': surahNumber, 'read': readId},
    );
    final timings = (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .where((item) => item['ayah'] is num && (item['ayah'] as num) > 0)
        .map((item) => QuranAyahTiming(
              ayah: (item['ayah'] as num).toInt(),
              start: Duration(milliseconds: (item['start_time'] as num).toInt()),
            ))
        .toList(growable: false);
    if (timings.isEmpty) throw StateError('Ayah timing unavailable');
    await prefs.setString(
      cacheKey,
      jsonEncode(timings
          .map((timing) => {'ayah': timing.ayah, 'start': timing.start.inMilliseconds})
          .toList()),
    );
    return timings;
  }

  @override
  Future<void> download(String url) async {
    await DefaultCacheManager().downloadFile(url);
    final prefs = await SharedPreferences.getInstance();
    final urls = prefs.getStringList(_downloadedUrlsKey) ?? <String>[];
    if (!urls.contains(url)) {
      urls.add(url);
      await prefs.setStringList(_downloadedUrlsKey, urls);
    }
  }

  @override
  Future<List<QuranDownloadedAudio>> downloadedAudios() async {
    final prefs = await SharedPreferences.getInstance();
    final urls = prefs.getStringList(_downloadedUrlsKey) ?? const <String>[];
    final items = <QuranDownloadedAudio>[];
    for (final url in urls) {
      for (final reciter in QuranReciter.all) {
        if (!url.startsWith(reciter.serverUrl)) continue;
        final filename = url.substring(reciter.serverUrl.length);
        final surahNumber = int.tryParse(filename.split('.').first);
        if (surahNumber != null && surahNumber >= 1 && surahNumber <= 114) {
          items.add(QuranDownloadedAudio(
            url: url,
            surahNumber: surahNumber,
            reciter: reciter,
          ));
        }
        break;
      }
    }
    return items;
  }

  @override
  Future<void> deleteDownloadedAudio(String url) async {
    await DefaultCacheManager().removeFile(url);
    final prefs = await SharedPreferences.getInstance();
    final urls = prefs.getStringList(_downloadedUrlsKey) ?? <String>[];
    urls.remove(url);
    await prefs.setStringList(_downloadedUrlsKey, urls);
  }
}
