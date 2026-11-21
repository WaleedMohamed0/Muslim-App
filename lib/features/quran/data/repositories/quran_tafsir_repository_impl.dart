import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../domain/repositories/quran_tafsir_repository.dart';

class QuranTafsirRepositoryImpl implements QuranTafsirRepository {
  QuranTafsirRepositoryImpl({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  // Flutter expands .gz assets and removes the suffix in the runtime bundle.
  static const _assetPath = 'assets/data/tafsir_muyassar.json';
  final AssetBundle _bundle;
  Future<Map<int, String>>? _tafsirByGlobalAyah;

  @override
  Future<String> getTafsir(int globalAyahNumber) async {
    final tafsir = await _loadDatasetOnce();
    final text = tafsir[globalAyahNumber];
    if (text == null) {
      throw FormatException('No offline Tafsir for Ayah $globalAyahNumber');
    }
    return text;
  }

  Future<Map<int, String>> _loadDatasetOnce() {
    return _tafsirByGlobalAyah ??= _loadDataset().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      // Keep retries meaningful if a bundle read or decode fails temporarily.
      _tafsirByGlobalAyah = null;
      developer.log(
        'Failed to load bundled Tafsir dataset',
        name: 'QuranTafsirRepository',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<Map<int, String>> _loadDataset() async {
    final asset = await _bundle.load(_assetPath);
    final assetBytes = asset.buffer.asUint8List(
      asset.offsetInBytes,
      asset.lengthInBytes,
    );
    final jsonText = utf8.decode(assetBytes);
    final decoded = jsonDecode(jsonText);
    if (decoded is! List || decoded.length != 6236) {
      throw const FormatException(
        'Offline Tafsir asset must contain 6236 JSON records',
      );
    }

    final tafsirByGlobalAyah = <int, String>{};
    var expectedGlobalNumber = 0;
    for (var surahNumber = 1; surahNumber <= 114; surahNumber++) {
      for (var ayahNumber = 1;
          ayahNumber <= quran.getVerseCount(surahNumber);
          ayahNumber++) {
        expectedGlobalNumber++;
        final row = decoded[expectedGlobalNumber - 1];
        if (row is! Map<String, dynamic>) {
          throw const FormatException(
            'Invalid record in offline Tafsir asset',
          );
        }
        final globalNumber = row['global_ayah_number'];
        final recordSurahNumber = row['surah_number'];
        final recordAyahNumber = row['ayah_number'];
        final text = row['tafsir'];
        if (row.length != 4 ||
            globalNumber is! int ||
            globalNumber != expectedGlobalNumber ||
            recordSurahNumber != surahNumber ||
            recordAyahNumber != ayahNumber ||
            text is! String ||
            text.isEmpty ||
            tafsirByGlobalAyah.containsKey(globalNumber)) {
          throw const FormatException(
            'Invalid or duplicate offline Tafsir record',
          );
        }
        tafsirByGlobalAyah[globalNumber] = text;
      }
    }
    if (tafsirByGlobalAyah.length != 6236) {
      throw FormatException(
        'Offline Tafsir asset has ${tafsirByGlobalAyah.length} records; expected 6236',
      );
    }
    return tafsirByGlobalAyah;
  }
}
