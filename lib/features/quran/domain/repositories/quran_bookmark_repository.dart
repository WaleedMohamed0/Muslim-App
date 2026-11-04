import '../entities/quran_bookmark.dart';

abstract interface class QuranBookmarkRepository {
  Future<QuranBookmark?> read();
  Future<void> save(QuranBookmark bookmark);
  Future<void> clear();
  Future<Set<String>> readAyahBookmarks();
  Future<void> saveAyahBookmarks(Set<String> bookmarks);
  Future<List<int>> readPageBookmarks();
  Future<void> savePageBookmarks(List<int> bookmarks);
}
