class StoryRecord {
  const StoryRecord({
    required this.id,
    required this.title,
    required this.sequence,
    required this.summary,
    required this.chapters,
    this.date = '',
  });

  factory StoryRecord.fromJson(Map<String, dynamic> json) => StoryRecord(
    id: json['id'] as String,
    title: json['name'] as String,
    sequence: json['sequence'] as int? ?? 0,
    summary: json['summary'] as String? ?? '',
    date: json['date'] as String? ?? '',
    chapters: (json['chapters'] as List<dynamic>? ?? const [])
        .map((item) => StoryChapter.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  final String id;
  final String title;
  final int sequence;
  final String summary;
  final String date;
  final List<StoryChapter> chapters;
}

class StoryChapter {
  const StoryChapter({
    required this.title,
    required this.content,
    required this.lessons,
    this.events = '',
    this.quranReferences = const [],
    this.hadithReferences = const [],
    this.historicalReferences = const [],
  });

  factory StoryChapter.fromJson(Map<String, dynamic> json) => StoryChapter(
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    lessons: json['lessons'] as String? ?? '',
    events: json['events'] as String? ?? '',
    quranReferences: (json['quranReferences'] as List<dynamic>? ?? const [])
        .cast<String>(),
    hadithReferences: (json['hadithReferences'] as List<dynamic>? ?? const [])
        .cast<String>(),
    historicalReferences:
        (json['historicalReferences'] as List<dynamic>? ?? const []).cast<String>(),
  );

  final String title;
  final String content;
  final String lessons;
  final String events;
  final List<String> quranReferences;
  final List<String> hadithReferences;
  final List<String> historicalReferences;
}
