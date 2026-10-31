import 'package:dio/dio.dart';

import '../../domain/repositories/quran_tafsir_repository.dart';

class QuranTafsirRepositoryImpl implements QuranTafsirRepository {
  QuranTafsirRepositoryImpl({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<int, String> _cache = {};

  @override
  Future<String> getTafsir(int globalAyahNumber) async {
    final cached = _cache[globalAyahNumber];
    if (cached != null) return cached;

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.alquran.cloud/v1/ayah/$globalAyahNumber/ar.muyassar',
      options: Options(receiveTimeout: const Duration(seconds: 12), sendTimeout: const Duration(seconds: 12)),
    );
    final text = response.data?['data']?['text'];
    if (response.statusCode != 200 || text is! String || text.trim().isEmpty) {
      throw const FormatException('Tafsir response did not contain text');
    }
    _cache[globalAyahNumber] = text;
    return text;
  }
}
