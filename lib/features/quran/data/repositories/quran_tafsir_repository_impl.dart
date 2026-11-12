import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/repositories/quran_tafsir_repository.dart';

class QuranTafsirRepositoryImpl implements QuranTafsirRepository {
  QuranTafsirRepositoryImpl({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const _assetPath = 'assets/data/tafsir_muyassar.json.gz';
  final AssetBundle _bundle;
  late final Future<Map<int, String>> _tafsirByGlobalAyah = _loadDataset();

  @override
  Future<String> getTafsir(int globalAyahNumber) async {
    final tafsir = await _tafsirByGlobalAyah;
    final text = tafsir[globalAyahNumber];
    if (text == null) {
      throw FormatException('No offline Tafsir for Ayah $globalAyahNumber');
    }
    return text;
  }

  Future<Map<int, String>> _loadDataset() async {
    final asset = await _bundle.load(_assetPath);
    final compressedBytes = asset.buffer.asUint8List(
      asset.offsetInBytes,
      asset.lengthInBytes,
    );
    final jsonText = utf8.decode(gzip.decode(compressedBytes));
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw const FormatException('Offline Tafsir asset must be a JSON array');
    }

    final tafsirByGlobalAyah = <int, String>{};
    for (final row in decoded) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Invalid record in offline Tafsir asset');
      }
      final globalNumber = row['global_ayah_number'];
      final surahNumber = row['surah_number'];
      final ayahNumber = row['ayah_number'];
      final text = row['tafsir'];
      if (row.length != 4 ||
          globalNumber is! int ||
          surahNumber is! int ||
          ayahNumber is! int ||
          text is! String ||
          text.isEmpty ||
          tafsirByGlobalAyah.containsKey(globalNumber)) {
        throw const FormatException('Invalid or duplicate offline Tafsir record');
      }
      tafsirByGlobalAyah[globalNumber] = text;
    }
    if (tafsirByGlobalAyah.length != 6236) {
      throw FormatException(
        'Offline Tafsir asset has ${tafsirByGlobalAyah.length} records; expected 6236',
      );
    }
    return tafsirByGlobalAyah;
  }
}
