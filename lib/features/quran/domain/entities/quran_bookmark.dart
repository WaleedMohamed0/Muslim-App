class QuranBookmark {
  const QuranBookmark({
    required this.pageNumber,
    this.surahNumber,
    this.ayahNumber,
  });

  /// Absolute Mushaf page number, independent of any Ayah bookmark.
  final int pageNumber;
  final int? surahNumber;
  final int? ayahNumber;
}
