import '../entities/quran_bookmark.dart';

abstract interface class QuranBookmarkRepository {
  Future<QuranBookmark?> read();
  Future<void> save(QuranBookmark bookmark);
  Future<void> clear();
}
