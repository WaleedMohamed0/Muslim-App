class HadeethEntry {
  const HadeethEntry({
    required this.text,
    required this.explanation,
    required this.narrator,
    required this.source,
    required this.number,
    required this.grade,
    required this.referenceUrl,
  });
  final String text;
  final String explanation;
  final String narrator;
  final String source;
  final String number;
  final String grade;
  final String referenceUrl;

  String get citation => '$grade — $source، حديث $number';
}
