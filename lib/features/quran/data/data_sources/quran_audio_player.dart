import 'package:just_audio/just_audio.dart';
import 'quran_audio_handler.dart';

class QuranAudioPlayer {
  QuranAudioPlayer(this.handler);

  final QuranAudioHandler handler;
  AudioPlayer get player => handler.player;

  Future<void> setUrl(String url) async => handler.setUrl(url);
  Future<void> setFile(String path) async => handler.setFile(path);
  Future<void> play() => handler.startPlayer();
  Future<void> pause() => handler.pausePlayer();
  Future<void> stop() => handler.stopPlayer();
  Future<void> seekToStart() async => player.seek(Duration.zero);
  Future<void> dispose() => handler.dispose();
}
