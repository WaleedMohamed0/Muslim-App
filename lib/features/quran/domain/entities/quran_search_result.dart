class QuranSearchResult {
  const QuranSearchResult({
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    required this.surahName,
    required this.juzNumber,
  });

  final int surahNumber;
  final int ayahNumber;
  final String text;
  final String surahName;
  final int juzNumber;
}
