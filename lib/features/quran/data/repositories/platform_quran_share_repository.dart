import 'package:flutter/services.dart';

import '../../domain/repositories/quran_share_repository.dart';

class PlatformQuranShareRepository implements QuranShareRepository {
  const PlatformQuranShareRepository();

  static const _channel = MethodChannel('com.muslim/quran_share');

  @override
  Future<void> shareText({required String text, required String title}) =>
      _channel.invokeMethod<void>('shareText', {'text': text, 'title': title});
}
