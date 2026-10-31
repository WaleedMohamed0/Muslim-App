import 'package:just_audio/just_audio.dart';

class QuranAudioPlayer {
  final AudioPlayer player = AudioPlayer();
  Future<void> setUrl(String url) async => player.setUrl(url);
  Future<void> setFile(String path) async => player.setFilePath(path);
  Future<void> play() async => player.play();
  Future<void> pause() async => player.pause();
  Future<void> stop() async => player.stop();
  Future<void> seekToStart() async => player.seek(Duration.zero);
  Future<void> dispose() => player.dispose();
}
