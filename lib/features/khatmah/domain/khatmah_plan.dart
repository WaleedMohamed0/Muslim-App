import 'package:quran/quran.dart' as quran;

class KhatmahDay {
  const KhatmahDay({required this.day, required this.startPage, required this.endPage});
  final int day;
  final int startPage;
  final int endPage;
  int get pages => endPage - startPage + 1;
  int get startSurah => (quran.getPageData(startPage).first as Map)['surah'] as int;
  int get startAyah => (quran.getPageData(startPage).first as Map)['start'] as int;
  int get endSurah => (quran.getPageData(endPage).last as Map)['surah'] as int;
  int get endAyah => (quran.getPageData(endPage).last as Map)['end'] as int;
  double get juz => pages / 604 * 30;
}

class KhatmahPlan {
  const KhatmahPlan({required this.durationDays, required this.startedAt,
    required this.completedPages, this.paused = false, this.reminderEnabled = false,
    this.reminderHour = 20, this.reminderMinute = 0});
  final int durationDays;
  final DateTime startedAt;
  final Set<int> completedPages;
  final bool paused;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  List<KhatmahDay> get schedule => List.generate(durationDays, (i) {
    final start = (i * 604 ~/ durationDays) + 1;
    final end = ((i + 1) * 604 ~/ durationDays);
    return KhatmahDay(day: i + 1, startPage: start, endPage: end);
  });
  int get currentDay => DateTime.now().difference(DateTime(startedAt.year, startedAt.month, startedAt.day)).inDays.clamp(0, durationDays - 1) + 1;
  bool isDayComplete(KhatmahDay day) => List.generate(day.pages, (i) => day.startPage + i).every(completedPages.contains);
  int get pagesRead => completedPages.length;
  double get progress => pagesRead / 604;
  int get remainingPages => 604 - pagesRead;
  KhatmahPlan copyWith({Set<int>? completedPages, bool? paused, bool? reminderEnabled, int? reminderHour, int? reminderMinute}) => KhatmahPlan(durationDays: durationDays, startedAt: startedAt, completedPages: completedPages ?? this.completedPages, paused: paused ?? this.paused, reminderEnabled: reminderEnabled ?? this.reminderEnabled, reminderHour: reminderHour ?? this.reminderHour, reminderMinute: reminderMinute ?? this.reminderMinute);
  Map<String, dynamic> toJson() => {'days': durationDays, 'started': startedAt.toIso8601String(), 'pages': completedPages.toList(), 'paused': paused, 'reminder': reminderEnabled, 'hour': reminderHour, 'minute': reminderMinute};
  factory KhatmahPlan.fromJson(Map<String, dynamic> json) => KhatmahPlan(durationDays: json['days'] as int, startedAt: DateTime.parse(json['started'] as String), completedPages: (json['pages'] as List).whereType<int>().where((p) => p >= 1 && p <= 604).toSet(), paused: json['paused'] as bool? ?? false, reminderEnabled: json['reminder'] as bool? ?? false, reminderHour: json['hour'] as int? ?? 20, reminderMinute: json['minute'] as int? ?? 0);
}
