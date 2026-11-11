import 'prayer_times.dart';

class NextPrayer {
  const NextPrayer({required this.id, required this.at});

  final String id;
  final DateTime at;
}

/// Returns the first prayer strictly after [now], rolling Fajr into tomorrow
/// once today's Isha has passed (or is exactly now).
NextPrayer? nextPrayerAfter(PrayerTimes? times, DateTime now) {
  if (times == null) return null;

  const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final timesOfDay = [
    times.fajr,
    times.dhuhr,
    times.asr,
    times.maghrib,
    times.isha,
  ];
  for (var index = 0; index < timesOfDay.length; index++) {
    final prayer = timesOfDay[index];
    final candidate = DateTime(
      now.year,
      now.month,
      now.day,
      prayer.hour,
      prayer.minute,
    );
    if (candidate.isAfter(now)) {
      return NextPrayer(id: prayers[index], at: candidate);
    }
  }

  final fajr = timesOfDay.first;
  return NextPrayer(
    id: prayers.first,
    at: DateTime(now.year, now.month, now.day + 1, fajr.hour, fajr.minute),
  );
}
