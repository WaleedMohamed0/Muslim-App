class QuranSound {
  List<String> audio = [];

  QuranSound();
  QuranSound.fromJson(Map<String, dynamic> json) {
    json['data']['ayahs'].forEach((obj) {
      audio.add(obj['audio']);
    });
  }
}
