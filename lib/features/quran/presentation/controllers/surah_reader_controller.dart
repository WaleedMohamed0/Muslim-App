import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';
import 'package:muslim/features/quran/domain/entities/quran_bookmark.dart';
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
      cubit.bookmark,
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
    final actualPage = MushafLineLayoutData.pageNumber(
      initialSurah,
      initialVerse,
    );
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
      if (!cubit.hasActivePlaybackSession &&
          cubit.surahNumber == initialSurah) {
        cubit.setCurrentPageNumber(initialVerse);
      }
    }

    _audioStateSubscription = cubit.stream.listen(
      (_) => _handleAudioStateChange(),
    );
    _scheduleControlsHide();
  }

  static const double minimumZoomScale = 1.0;
  static const double maximumZoomScale = 3.0;
  static const double zoomStep = .25;

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
  double _zoomScale = 1;
  bool _controlsVisible = true;

  int get pageIndex => _pageIndex;
  int get pageNumber => _pageIndex + 1;
  int get visibleSurahNumber => _visibleSurahNumber;
  int get currentAyah => _readerCurrentAyah;
  String get surahName => _surahName;
  double get zoomScale => _zoomScale;
  bool get canZoomOut => _zoomScale > minimumZoomScale;
  bool get canZoomIn => _zoomScale < maximumZoomScale;
  bool get controlsVisible => _controlsVisible;
  bool get isFirstPage => _pageIndex == (_minimumPageNumber ?? 1) - 1;
  bool get isLastPage =>
      _pageIndex >= (_maximumPageNumber ?? quran.totalPagesCount) - 1;
  bool get isCurrentPageBookmarked => cubit.pageBookmarks.contains(pageNumber);

  int? get bookmarkAyahForPlayback {
    if (cubit.pageBookmarks.contains(pageNumber)) {
      final pageData = MushafLineLayoutData.pageData(pageNumber);
      return pageData.first['start'];
    }
    if (cubit.ayahBookmarks.contains(
      '$_visibleSurahNumber:$_readerCurrentAyah',
    )) {
      return _readerCurrentAyah;
    }
    return null;
  }

  static int? _bookmarkAyahForSurah(QuranBookmark? bookmark, int surahNumber) {
    if (bookmark == null) return null;
    if (bookmark.surahNumber == surahNumber && bookmark.ayahNumber != null) {
      return bookmark.ayahNumber;
    }
    for (final section in MushafLineLayoutData.pageData(bookmark.pageNumber)) {
      if (section['surah'] == surahNumber) {
        return section['start'];
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
        target > (_maximumPageNumber ?? quran.totalPagesCount) - 1)
      return;
    pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void goToPage(int pageNumber) {
    final target = pageNumber.clamp(1, quran.totalPagesCount).toInt() - 1;
    if (target == _pageIndex) return;
    pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void scrubToPage(int pageNumber) {
    final target = pageNumber.clamp(1, quran.totalPagesCount).toInt() - 1;
    if (target == _pageIndex) return;
    pageController.jumpToPage(target);
  }

  void handlePageChanged(int index, int initialSurah) {
    final pageEntries = MushafLineLayoutData.pageData(index + 1);
    final first = pageEntries.first;
    final firstSurahNumber = first['surah']!;
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
        MushafLineLayoutData.pageNumber(playbackSurah, playbackAyah) - 1 ==
            index;
    final initialSurahIsOnPage =
        preserveInitialAyah &&
        pageEntries.any((entry) => entry['surah'] == initialSurah);

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
            : first['start']!;

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
    if (_saveGeneralCheckpoint)
      cubit.saveReaderPosition(surahNumber, verseNumber);
    _scheduleControlsHide();
  }

  void adjustZoom(double delta) {
    final next = (_zoomScale + delta)
        .clamp(minimumZoomScale, maximumZoomScale)
        .toDouble();
    if (next == _zoomScale) return;
    zoomController.value = Matrix4.diagonal3Values(next, next, 1);
    _zoomScale = next;
    notifyListeners();
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

  void syncZoomScale() {
    if (_disposed) return;
    final scale =
        zoomController.value.getMaxScaleOnAxis().clamp(minimumZoomScale, maximumZoomScale).toDouble();
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
    await cubit.togglePageBookmark(
      page,
      locationSurahNumber: _visibleSurahNumber,
      locationAyahNumber: _readerCurrentAyah,
    );
    if (!_disposed) notifyListeners();
    if (wasBookmarked) return null;
    final first = MushafLineLayoutData.pageData(page).first;
    return first['surah'];
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
        final targetPage =
            MushafLineLayoutData.pageNumber(surahNumber, ayahNumber) - 1;
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
        if (_saveGeneralCheckpoint)
          cubit.saveReaderPosition(surahNumber, ayahNumber);
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
