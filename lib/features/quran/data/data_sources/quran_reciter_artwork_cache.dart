import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/quran_reciter.dart';

/// Copies bundled portrait assets to app support storage so Android's media
/// session can read artwork through a stable `file://` URI while offline.
class QuranReciterArtworkCache {
  QuranReciterArtworkCache._();

  static final Map<String, Future<Uri?>> _pending = {};

  static Future<Uri?> fileUriFor(QuranReciter reciter) async {
    final pending = _pending.putIfAbsent(
      reciter.id,
      () => _copyPortrait(reciter),
    );
    final uri = await pending;
    // A transient asset/storage failure must not poison this cache for the
    // remainder of the app process; the caller can retry on the next update.
    if (uri == null && identical(_pending[reciter.id], pending)) {
      _pending.remove(reciter.id);
    }
    return uri;
  }

  static Future<Uri?> _copyPortrait(QuranReciter reciter) async {
    final candidates = <MapEntry<String, String>>[
      if (reciter.avatarAsset != null)
        MapEntry(
          reciter.avatarAsset!,
          'reciter_${reciter.id}${reciter.avatarAsset!.substring(reciter.avatarAsset!.lastIndexOf('.'))}',
        ),
      const MapEntry(
        'assets/features/app/images/quran_logo.webp',
        'quran_notification_artwork.png',
      ),
    ];
    for (final candidate in candidates) {
      final asset = candidate.key;
      try {
        final directory = await getApplicationSupportDirectory();
        final file = File(
          '${directory.path}${Platform.pathSeparator}${candidate.value}',
        );
        if (!await file.exists() || await file.length() == 0) {
          final data = await rootBundle.load(asset);
          await file.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true,
          );
        }
        if (await file.length() > 0) return Uri.file(file.path);
      } catch (_) {
        // Try the built-in default portrait if a selected asset cannot be read.
      }
    }
    return null;
  }
}
