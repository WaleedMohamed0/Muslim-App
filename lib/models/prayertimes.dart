class PrayerTimesModel {
  String? Fajr;
  String? Dhuhr;
  String? Asr;
  String? Maghrib;
  String? Isha;
  String? date;

  DateTime now = DateTime.now();


  PrayerTimesModel.fromJson(Map<String,dynamic> json)
  {
    Fajr = json['data'][now.day-1]['timings']['Fajr'];
    Dhuhr = json['data'][now.day-1]['timings']['Dhuhr'];
    Asr = json['data'][now.day-1]['timings']['Asr'];
    Maghrib = json['data'][now.day-1]['timings']['Maghrib'];
    Isha = json['data'][now.day-1]['timings']['Isha'];
  }
}
