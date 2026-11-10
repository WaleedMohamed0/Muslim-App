import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/storage/cache_helper.dart';
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';

/// Owns the state transitions and Cubit coordination for one reader session.
class SurahReaderController extends ChangeNotifier {
  SurahReaderController({
    required this.cubit,
    required int initialSurah,
    int? initialAyah,
    int? initialPageNumber,
    void Function(int page, int surah, int ayah)? onPageRead,
    bool saveGeneralCheckpoint = true,
    int? minimumPageNumber,
    int? maximumPageNumber,
  }) : _onPageRead = onPageRead {
    _saveGeneralCheckpoint = saveGeneralCheckpoint;
    _minimumPageNumber = minimumPageNumber;
    _maximumPageNumber = maximumPageNumber;
    _readerOnlyDuringOtherPlayback = false;
    final savedReaderPosition = cubit.lastReaderAyahForSurah(initialSurah);
    final savedPlaybackPosition = cubit.lastAyahForSurah(initialSurah);
    final bookmarkedAyah = _bookmarkAyahForSurah(
      cubit.bookmark?.pageNumber,
      initialSurah,
    );
    final initialVerse =
        (initialAyah ??
                savedReaderPosition ??
                savedPlaybackPosition ??
                bookmarkedAyah ??
                1)
            .clamp(1, quran.getVerseCount(initialSurah))
            .toInt();

    _visibleSurahNumber = initialSurah;
    _surahName = _surahNameFor(initialSurah);
    final actualPage = quran.getPageNumber(initialSurah, initialVerse);
    final pageNumber =
        initialPageNumber == actualPage ? initialPageNumber! : actualPage;
    _pageIndex = pageNumber - 1;
    _readerCurrentAyah = initialVerse;
    _pendingInitialPageIndex = _pageIndex;
    _pendingInitialAyah = initialVerse;
    pageController = PageController(initialPage: _pageIndex);
    zoomController = TransformationController();
    _lastPlaybackNavigationRevision = cubit.surahPlaybackNavigationRevision;

    if (!_readerOnlyDuringOtherPlayback) {
      if (cubit.surahNumber != initialSurah) {
        unawaited(
          cubit.selectSurah(initialSurah, _surahName, online: cubit.isOnline),
        );
      } else {
        cubit.setSurahInfo(initialSurah, _surahName);
      }
      if (!cubit.hasActivePlaybackSession && cubit.surahNumber == initialSurah) {
        cubit.setCurrentPageNumber(initialVerse);
      }
    }

    _audioStateSubscription = cubit.stream.listen(
      (_) => _handleAudioStateChange(),
    );
    _scheduleControlsHide();
    unawaited(_restoreFontSizePreference());
  }

  static const _fontSizePreferenceKey = 'quran_reader_font_size';
  static const _minimumFontSize = 22.0;
  static const _maximumFontSize = 32.0;

  final QuranCubit cubit;
  final void Function(int page, int surah, int ayah)? _onPageRead;
  late final bool _saveGeneralCheckpoint;
  late final int? _minimumPageNumber;
  late final int? _maximumPageNumber;
  late final PageController pageController;
  late final TransformationController zoomController;
  late final StreamSubscription<QuranState> _audioStateSubscription;
  Timer? _controlsTimer;
  bool _disposed = false;
  bool _fontSizeChangedBeforeRestore = false;
  bool _readerOnlyDuringOtherPlayback = false;
  late int _lastPlaybackNavigationRevision;
  int? _playbackNavigationSurahOverride;
  int? _playbackNavigationAyahOverride;
  int _pageIndex = 0;
  int _visibleSurahNumber = 1;
  int _readerCurrentAyah = 1;
  int? _pendingInitialPageIndex;
  int? _pendingInitialAyah;
  String _surahName = '';
  double _fontSize = 22;
  double _zoomScale = 1;
  bool _controlsVisible = true;

  int get pageIndex => _pageIndex;
  int get pageNumber => _pageIndex + 1;
  int get visibleSurahNumber => _visibleSurahNumber;
  int get currentAyah => _readerCurrentAyah;
  String get surahName => _surahName;
  double get fontSize => _fontSize;
  double get zoomScale => _zoomScale;
  bool get controlsVisible => _controlsVisible;
  bool get isFirstPage => _pageIndex == (_minimumPageNumber ?? 1) - 1;
  bool get isLastPage => _pageIndex >= (_maximumPageNumber ?? quran.totalPagesCount) - 1;
  bool get isCurrentPageBookmarked => cubit.pageBookmarks.contains(pageNumber);

  int? get bookmarkAyahForPlayback {
    if (cubit.pageBookmarks.contains(pageNumber)) {
      final pageData = quran.getPageData(pageNumber).cast<Map>();
      return (pageData.first['start'] as num).toInt();
    }
    if (cubit.ayahBookmarks.contains(
      '$_visibleSurahNumber:$_readerCurrentAyah',
    )) {
      return _readerCurrentAyah;
    }
    return null;
  }

  static int? _bookmarkAyahForSurah(int? mushafPage, int surahNumber) {
    if (mushafPage == null) return null;
    for (final entry in quran.getPageData(mushafPage)) {
      final section = entry as Map;
      if ((section['surah'] as num).toInt() == surahNumber) {
        return (section['start'] as num).toInt();
      }
    }
    return null;
  }

  static String _surahNameFor(int surahNumber) {
    final name = UthmaniQuranText.getSurahName(surahNumber);
    return name == 'اللهب' ? 'المسد' : name;
  }

  void turnPage({required bool next}) {
    final target = _pageIndex + (next ? 1 : -1);
    if (target < (_minimumPageNumber ?? 1) - 1 ||
        target > (_maximumPageNumber ?? quran.totalPagesCount) - 1) return;
    pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void handlePageChanged(int index, int initialSurah) {
    final pageEntries = quran.getPageData(index + 1);
    final first = pageEntries.first as Map;
    final firstSurahNumber = (first['surah'] as num).toInt();
    final preserveInitialAyah =
        _pendingInitialPageIndex == index && _pendingInitialAyah != null;
    final pendingInitialAyah = _pendingInitialAyah;
    _pendingInitialPageIndex = null;
    _pendingInitialAyah = null;

    final playbackSurah = _playbackNavigationSurahOverride;
    final playbackAyah = _playbackNavigationAyahOverride;
    final usePlaybackOverride =
        playbackSurah != null &&
        playbackAyah != null &&
        quran.getPageNumber(playbackSurah, playbackAyah) - 1 == index;
    final initialSurahIsOnPage =
        preserveInitialAyah &&
        pageEntries.any(
          (entry) => ((entry as Map)['surah'] as num).toInt() == initialSurah,
        );

    final surahNumber =
        usePlaybackOverride
            ? playbackSurah
            : initialSurahIsOnPage
            ? initialSurah
            : firstSurahNumber;
    final verseNumber =
        usePlaybackOverride
            ? playbackAyah
            : initialSurahIsOnPage
            ? pendingInitialAyah!
            : (first['start'] as num).toInt();

    if (usePlaybackOverride) {
      _playbackNavigationSurahOverride = null;
      _playbackNavigationAyahOverride = null;
    }
    _setReaderPosition(
      pageIndex: index,
      surahNumber: surahNumber,
      ayahNumber: verseNumber,
    );
    _onPageRead?.call(index + 1, surahNumber, verseNumber);
    if (_saveGeneralCheckpoint) cubit.saveReaderPosition(surahNumber, verseNumber);
    _scheduleControlsHide();
  }

  void selectAyah(int surahNumber, int verseNumber) {
    _surahName = _surahNameFor(surahNumber);
    _visibleSurahNumber = surahNumber;
    _readerCurrentAyah = verseNumber;
    if (!cubit.hasActivePlaybackSession) {
      cubit.setSurahInfo(surahNumber, _surahName);
      cubit.setCurrentPageNumber(verseNumber);
    }
    notifyListeners();
  }

  void changeFontSize(double value) {
    final nextSize = value.clamp(_minimumFontSize, _maximumFontSize).toDouble();
    if (nextSize == _fontSize) return;
    _fontSizeChangedBeforeRestore = true;
    _fontSize = nextSize;
    notifyListeners();
    unawaited(_persistFontSizePreference(nextSize.round()));
    _scheduleControlsHide();
  }

  void syncZoomScale() {
    if (_disposed) return;
    final scale =
        zoomController.value.getMaxScaleOnAxis().clamp(1.0, 3.0).toDouble();
    if ((scale - _zoomScale).abs() > .02) {
      _zoomScale = scale;
      notifyListeners();
    }
  }

  void toggleControls() {
    _controlsVisible = !_controlsVisible;
    notifyListeners();
    if (_controlsVisible) _scheduleControlsHide();
  }

  Future<int?> togglePageBookmark() async {
    final page = pageNumber;
    final wasBookmarked = cubit.pageBookmarks.contains(page);
    await cubit.togglePageBookmark(page);
    if (!_disposed) notifyListeners();
    if (wasBookmarked) return null;
    final first = quran.getPageData(page).first as Map;
    return (first['surah'] as num).toInt();
  }

  Future<int?> toggleAyahBookmark(int surahNumber, int verseNumber) async {
    final key = '$surahNumber:$verseNumber';
    final wasBookmarked = cubit.ayahBookmarks.contains(key);
    await cubit.toggleAyahBookmark(surahNumber, verseNumber);
    if (!_disposed) notifyListeners();
    return wasBookmarked ? null : surahNumber;
  }

  void _setReaderPosition({
    required int pageIndex,
    required int surahNumber,
    required int ayahNumber,
  }) {
    _pageIndex = pageIndex;
    _visibleSurahNumber = surahNumber;
    _surahName = _surahNameFor(surahNumber);
    _readerCurrentAyah = ayahNumber;
    _zoomScale = 1;
    zoomController.value = Matrix4.identity();
    notifyListeners();
  }

  void _handleAudioStateChange() {
    if (_disposed) return;
    final revision = cubit.surahPlaybackNavigationRevision;
    if (revision != _lastPlaybackNavigationRevision) {
      _lastPlaybackNavigationRevision = revision;
      final surahNumber = cubit.surahPlaybackNavigationTarget;
      final ayahNumber = cubit.surahPlaybackNavigationAyah;
      if (surahNumber >= 1 && surahNumber <= quran.totalSurahCount) {
        final targetPage = quran.getPageNumber(surahNumber, ayahNumber) - 1;
        _readerOnlyDuringOtherPlayback = false;
        _playbackNavigationSurahOverride =
            targetPage == _pageIndex ? null : surahNumber;
        _playbackNavigationAyahOverride =
            targetPage == _pageIndex ? null : ayahNumber;
        _setReaderPosition(
          pageIndex: targetPage,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        );
        if (_saveGeneralCheckpoint) cubit.saveReaderPosition(surahNumber, ayahNumber);
        if (pageController.hasClients &&
            pageController.page?.round() != targetPage) {
          pageController.jumpToPage(targetPage);
        }
      }
    }
    _restoreReaderAfterPlaybackEnds();
  }

  void _restoreReaderAfterPlaybackEnds() {
    if (_disposed ||
        !_readerOnlyDuringOtherPlayback ||
        cubit.hasActivePlaybackSession) {
      return;
    }
    _readerOnlyDuringOtherPlayback = false;
    cubit.setSurahInfo(_visibleSurahNumber, _surahName);
    cubit.setCurrentPageNumber(_readerCurrentAyah);
  }

  Future<void> _persistFontSizePreference(int fontSize) async {
    try {
      await CacheHelper.saveData(key: _fontSizePreferenceKey, value: fontSize);
    } catch (_) {
      // Reader preferences are optional; keep using the current in-memory size.
    }
  }

  Future<void> _restoreFontSizePreference() async {
    try {
      await CacheHelper.ensureInitialized();
      final savedSize = CacheHelper.getData(key: _fontSizePreferenceKey);
      if (_disposed || _fontSizeChangedBeforeRestore || savedSize is! int) {
        return;
      }
      final restoredSize =
          savedSize
              .clamp(_minimumFontSize.round(), _maximumFontSize.round())
              .toDouble();
      if (restoredSize != _fontSize) {
        _fontSize = restoredSize;
        notifyListeners();
      }
    } catch (_) {
      // Fall back to the default font size when preferences cannot be read.
    }
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (_disposed || !_controlsVisible) return;
      _controlsVisible = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _controlsTimer?.cancel();
    unawaited(_audioStateSubscription.cancel());
    pageController.dispose();
    zoomController.dispose();
    super.dispose();
  }
}
