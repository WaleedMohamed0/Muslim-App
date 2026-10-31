import '../../../../core/storage/cache_helper.dart';
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';

class QuranBookmarkRepositoryImpl implements QuranBookmarkRepository {
  @override
  Future<QuranBookmark?> read() async {
    final name = CacheHelper.getData(key: 'surahName') as String?;
    final surah = CacheHelper.getData(key: 'surahNumber') as int?;
    final page = CacheHelper.getData(key: 'pageNumber') as int?;
    if (name == null || surah == null || page == null) return null;
    return QuranBookmark(surahNumber: surah, surahName: name, pageNumber: page);
  }

  @override
  Future<void> save(QuranBookmark bookmark) async {
    await CacheHelper.saveData(key: 'surahName', value: bookmark.surahName);
    await CacheHelper.saveData(key: 'surahNumber', value: bookmark.surahNumber);
    await CacheHelper.saveData(key: 'pageNumber', value: bookmark.pageNumber);
  }

  @override
  Future<void> clear() async {
    await CacheHelper.removeData(key: 'surahName');
    await CacheHelper.removeData(key: 'surahNumber');
    await CacheHelper.removeData(key: 'pageNumber');
  }
}
