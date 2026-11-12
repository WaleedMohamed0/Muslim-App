import 'package:quran/quran.dart' as quran;
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';

import '../../../../core/storage/cache_helper.dart';
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';

class QuranBookmarkRepositoryImpl implements QuranBookmarkRepository {
  static const _pageBookmarkKey = 'quran_page_bookmark';
  static const _pageBookmarksKey = 'quran_page_bookmarks';
  static const _ayahBookmarksKey = 'quran_ayah_bookmarks';

  @override
  Future<QuranBookmark?> read() async {
    final pages = await readPageBookmarks();
    return pages.isEmpty ? null : QuranBookmark(pageNumber: pages.last);
  }

  @override
  Future<List<int>> readPageBookmarks() async {
    await CacheHelper.ensureInitialized();
    final savedPages = CacheHelper.getData(key: _pageBookmarksKey);
    if (savedPages is List<String>) {
      return savedPages
          .map(int.tryParse)
          .whereType<int>()
          .where((page) => page >= 1 && page <= quran.totalPagesCount)
          .toSet()
          .toList(growable: true);
    }

    final savedPage = CacheHelper.getData(key: _pageBookmarkKey) as int?;
    if (savedPage != null &&
        savedPage >= 1 &&
        savedPage <= quran.totalPagesCount) {
      final pages = [savedPage];
      await savePageBookmarks(pages);
      return pages;
    }

    // Migrate the previous mixed bookmark format as a page bookmark. Its old
    // `pageNumber` value was actually the first Ayah of the bookmarked page.
    final name = CacheHelper.getData(key: 'surahName') as String?;
    final surah = CacheHelper.getData(key: 'surahNumber') as int?;
    final oldAyah = CacheHelper.getData(key: 'pageNumber') as int?;
    if (name == null ||
        surah == null ||
        oldAyah == null ||
        surah < 1 ||
        surah > 114) {
      return <int>[];
    }
    final ayah = oldAyah.clamp(1, quran.getVerseCount(surah)).toInt();
    final migratedPage = MushafLineLayoutData.pageNumber(surah, ayah);
    final pages = [migratedPage];
    await savePageBookmarks(pages);
    await CacheHelper.removeData(key: 'surahName');
    await CacheHelper.removeData(key: 'surahNumber');
    await CacheHelper.removeData(key: 'pageNumber');
    return pages;
  }

  @override
  Future<void> save(QuranBookmark bookmark) async {
    await savePageBookmarks([bookmark.pageNumber]);
  }

  @override
  Future<void> clear() async {
    await CacheHelper.removeData(key: _pageBookmarkKey);
    await CacheHelper.removeData(key: _pageBookmarksKey);
    await CacheHelper.removeData(key: 'surahName');
    await CacheHelper.removeData(key: 'surahNumber');
    await CacheHelper.removeData(key: 'pageNumber');
  }

  @override
  Future<Set<String>> readAyahBookmarks() async {
    await CacheHelper.ensureInitialized();
    final saved = CacheHelper.getData(key: _ayahBookmarksKey);
    if (saved is! List<String>) return <String>{};
    return saved.where((key) => _isValidAyahKey(key)).toSet();
  }

  @override
  Future<void> saveAyahBookmarks(Set<String> bookmarks) async {
    await CacheHelper.saveData(
      key: _ayahBookmarksKey,
      value: bookmarks.toList(growable: false),
    );
  }

  @override
  Future<void> savePageBookmarks(List<int> bookmarks) async {
    final validPages = bookmarks
        .where((page) => page >= 1 && page <= quran.totalPagesCount)
        .toSet()
        .toList(growable: false);
    await CacheHelper.saveData(
      key: _pageBookmarksKey,
      value: validPages.map((page) => page.toString()).toList(growable: false),
    );
    if (validPages.isEmpty) {
      await CacheHelper.removeData(key: _pageBookmarkKey);
    } else {
      await CacheHelper.saveData(key: _pageBookmarkKey, value: validPages.last);
    }
    await CacheHelper.removeData(key: 'surahName');
    await CacheHelper.removeData(key: 'surahNumber');
    await CacheHelper.removeData(key: 'pageNumber');
  }

  bool _isValidAyahKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return false;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    return surah != null &&
        ayah != null &&
        surah >= 1 &&
        surah <= 114 &&
        ayah >= 1 &&
        ayah <= quran.getVerseCount(surah);
  }
}
