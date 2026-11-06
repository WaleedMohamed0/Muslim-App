import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:untitled8/core/utils/arabic_digits.dart';
import 'package:untitled8/core/storage/cache_helper.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_state.dart';
import 'package:untitled8/features/quran/presentation/widgets/mushaf_text_page.dart';
import 'package:untitled8/features/quran/presentation/widgets/quran_reader_audio_controls.dart';
import 'package:untitled8/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:untitled8/features/quran/presentation/widgets/quran_reader_sheets.dart';
import 'package:untitled8/features/quran/presentation/widgets/reader_controls_overlay.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.initialPageNumber,
  });
  final int surahNumber;
  final int? initialAyah;
  final int? initialPageNumber;

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  static const _fontSizePreferenceKey = 'quran_reader_font_size';
  static const _minimumFontSize = 16.0;
  static const _maximumFontSize = 32.0;

  late final QuranCubit _cubit;
  late String _surahName;
  late int _visibleSurahNumber;
  late final PageController _pageController;
  late final TransformationController _zoomController;
  StreamSubscription<QuranState>? _audioStateSubscription;
  double _zoomScale = 1;
  double _fontSize = 19;
  bool _fontSizeChangedBeforeRestore = false;
  bool _readerOnlyDuringOtherPlayback = false;
  late int _lastSurahPlaybackNavigationRevision;
  int? _playbackNavigationSurahOverride;
  int? _playbackNavigationAyahOverride;
  int _pageIndex = 0;
  int _readerCurrentAyah = 1;
  int? _pendingInitialPageIndex;
  int? _pendingInitialAyah;
  bool _controlsVisible = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreFontSizePreference());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _cubit = context.read<QuranCubit>();
    _readerOnlyDuringOtherPlayback =
        _cubit.hasActivePlaybackSession &&
        _cubit.surahNumber != widget.surahNumber;
    final savedReaderPosition = _cubit.lastReaderAyahForSurah(
      widget.surahNumber,
    );
    final savedPlaybackPosition = _cubit.lastAyahForSurah(widget.surahNumber);
    final pageBookmarkAyah = _bookmarkAyahForSurah(
      _cubit.bookmark?.pageNumber,
      widget.surahNumber,
    );
    final bookmarkedVerse = (widget.initialAyah ??
            savedReaderPosition ??
            savedPlaybackPosition ??
            pageBookmarkAyah ??
            1)
        .clamp(1, quran.getVerseCount(widget.surahNumber))
        .toInt();
    _visibleSurahNumber = widget.surahNumber;
    final rawName = quran.getSurahNameArabic(_visibleSurahNumber);
    _surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    final actualPage = quran.getPageNumber(widget.surahNumber, bookmarkedVerse);
    final requestedPage = widget.initialPageNumber;
    final pageNumber = requestedPage == actualPage ? requestedPage! : actualPage;
    _pageIndex = pageNumber - 1;
    _readerCurrentAyah = bookmarkedVerse;
    _pendingInitialPageIndex = _pageIndex;
    _pendingInitialAyah = bookmarkedVerse;
    _pageController = PageController(initialPage: _pageIndex);
    _zoomController = TransformationController();
    _lastSurahPlaybackNavigationRevision =
        _cubit.surahPlaybackNavigationRevision;
    if (!_readerOnlyDuringOtherPlayback) {
      _cubit.setSurahInfo(widget.surahNumber, _surahName);
      if (!_cubit.hasActivePlaybackSession) {
        _cubit.setCurrentPageNumber(bookmarkedVerse);
      }
    }
    _audioStateSubscription = _cubit.stream.listen(
      (_) => _handleAudioStateChange(),
    );
    _scheduleControlsHide();
  }

  int? _bookmarkAyahForSurah(int? mushafPage, int surahNumber) {
    if (mushafPage == null) return null;
    for (final entry in quran.getPageData(mushafPage)) {
      final section = entry as Map;
      if ((section['surah'] as num).toInt() == surahNumber) {
        return (section['start'] as num).toInt();
      }
    }
    return null;
  }

  String _surahNameForConfirmation(int surahNumber) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!isArabic) return quran.getSurahNameEnglish(surahNumber);
    final rawName = quran.getSurahNameArabic(surahNumber);
    return rawName == 'اللهب' ? 'المسد' : rawName;
  }

  Future<void> _toggleCurrentPageBookmark() async {
    final pageNumber = _pageIndex + 1;
    final isRemoving = _cubit.pageBookmarks.contains(pageNumber);
    await _cubit.togglePageBookmark(pageNumber);
    if (isRemoving || !mounted) return;
    final pageEntries = quran.getPageData(pageNumber).cast<Map>();
    final surahNumber = (pageEntries.first['surah'] as num).toInt();
    final surahName = _surahNameForConfirmation(surahNumber);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    AppSnackBar.show(
      message: isArabic
          ? 'تم حفظ سورة $surahName في العلامات المرجعية'
          : 'Surah $surahName has been saved to bookmarks.',
      success: true,
    );
  }

  Future<void> _toggleAyahBookmark(int surahNumber, int verseNumber) async {
    final key = '$surahNumber:$verseNumber';
    final isRemoving = _cubit.ayahBookmarks.contains(key);
    await _cubit.toggleAyahBookmark(surahNumber, verseNumber);
    if (isRemoving || !mounted) return;
    final surahName = _surahNameForConfirmation(surahNumber);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    AppSnackBar.show(
      message: isArabic
          ? 'تم حفظ سورة $surahName في العلامات المرجعية'
          : 'Surah $surahName has been saved to bookmarks.',
      success: true,
    );
  }

  int? _savedPlaybackAyahForCurrentPage() {
    final mushafPage = _pageIndex + 1;
    if (_cubit.pageBookmarks.contains(mushafPage)) {
      final pageData = quran.getPageData(mushafPage).cast<Map>();
      final firstSection = pageData.first;
      return (firstSection['start'] as num).toInt();
    }
    final selectedAyah = _readerCurrentAyah;
    if (_cubit.ayahBookmarks.contains(
      '$_visibleSurahNumber:$selectedAyah',
    )) {
      return selectedAyah;
    }
    return null;
  }

  void _handlePlaybackSessionEnded() {
    if (!mounted ||
        !_readerOnlyDuringOtherPlayback ||
        _cubit.hasActivePlaybackSession) {
      return;
    }

    // This reader was opened for a different Surah while another audio
    // session was active. Once that session ends, restore the reader context
    // to the Cubit without changing the page the user has manually selected.
    _readerOnlyDuringOtherPlayback = false;
    _cubit.setSurahInfo(_visibleSurahNumber, _surahName);
    _cubit.setCurrentPageNumber(_readerCurrentAyah);
  }

  void _handleAudioStateChange() {
    if (!mounted) return;

    final navigationRevision = _cubit.surahPlaybackNavigationRevision;
    if (navigationRevision != _lastSurahPlaybackNavigationRevision) {
      _lastSurahPlaybackNavigationRevision = navigationRevision;
      final targetSurah = _cubit.surahPlaybackNavigationTarget;
      final targetAyah = _cubit.surahPlaybackNavigationAyah;
      if (targetSurah >= 1 && targetSurah <= quran.totalSurahCount) {
        final targetPage = quran.getPageNumber(targetSurah, targetAyah) - 1;
        final rawName = quran.getSurahNameArabic(targetSurah);
        final targetName = rawName == 'اللهب' ? 'المسد' : rawName;
        _readerOnlyDuringOtherPlayback = false;
        _playbackNavigationSurahOverride =
            targetPage == _pageIndex ? null : targetSurah;
        _playbackNavigationAyahOverride =
            targetPage == _pageIndex ? null : targetAyah;
        setState(() {
          _visibleSurahNumber = targetSurah;
          _surahName = targetName;
          _pageIndex = targetPage;
          _readerCurrentAyah = targetAyah;
          _zoomScale = 1;
          _zoomController.value = Matrix4.identity();
        });
        _cubit.saveReaderPosition(targetSurah, targetAyah);
        if (_pageController.hasClients &&
            _pageController.page?.round() != targetPage) {
          _pageController.jumpToPage(targetPage);
        }
      }
    }

    _handlePlaybackSessionEnded();
  }

  void _changeZoom(double value) {
    _zoomScale = value.clamp(1, 3).toDouble();
    _zoomController.value = Matrix4.identity()..scale(_zoomScale);
    setState(() {});
  }

  void _changeFontSize(double value) {
    final nextSize = value
        .clamp(_minimumFontSize, _maximumFontSize)
        .toDouble();
    if (nextSize == _fontSize) return;
    _fontSizeChangedBeforeRestore = true;
    setState(() => _fontSize = nextSize);
    unawaited(_persistFontSizePreference(nextSize.round()));
    _scheduleControlsHide();
  }

  Future<void> _persistFontSizePreference(int fontSize) async {
    try {
      await CacheHelper.saveData(
        key: _fontSizePreferenceKey,
        value: fontSize,
      );
    } catch (_) {
      // Keep the reader usable if local preference storage is unavailable.
    }
  }

  Future<void> _restoreFontSizePreference() async {
    try {
      await CacheHelper.ensureInitialized();
      final savedSize = CacheHelper.getData(key: _fontSizePreferenceKey);
      if (!mounted ||
          _fontSizeChangedBeforeRestore ||
          savedSize is! int) {
        return;
      }
      final restoredSize = savedSize
          .clamp(_minimumFontSize.round(), _maximumFontSize.round())
          .toDouble();
      if (restoredSize != _fontSize) {
        setState(() => _fontSize = restoredSize);
      }
    } catch (_) {
      // Fall back to the default font size when preferences cannot be read.
    }
  }

  void _syncZoomScale() {
    if (!mounted) return;
    final scale = _zoomController.value
        .getMaxScaleOnAxis()
        .clamp(1.0, 3.0)
        .toDouble();
    if ((scale - _zoomScale).abs() > .02) {
      setState(() => _zoomScale = scale);
    }
  }

  void _turnPage({required bool next}) {
    final target = _pageIndex + (next ? 1 : -1);
    if (target < 0 || target >= quran.totalPagesCount) return;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    final pageEntries = quran.getPageData(index + 1);
    final first = pageEntries.first as Map;
    final firstSurahNumber = (first['surah'] as num).toInt();
    final pendingInitialPage = _pendingInitialPageIndex;
    final pendingInitialAyah = _pendingInitialAyah;
    final preserveInitialAyah =
        pendingInitialPage == index && pendingInitialAyah != null;
    _pendingInitialPageIndex = null;
    _pendingInitialAyah = null;
    final playbackSurahOverride = _playbackNavigationSurahOverride;
    final playbackAyahOverride = _playbackNavigationAyahOverride;
    final usePlaybackSurahOverride =
        playbackSurahOverride != null &&
        playbackAyahOverride != null &&
        quran.getPageNumber(playbackSurahOverride, playbackAyahOverride) - 1 ==
            index;
    final initialSurahIsOnPage = preserveInitialAyah &&
        pageEntries.any(
          (entry) =>
              ((entry as Map)['surah'] as num).toInt() == widget.surahNumber,
        );
    final surahNumber = usePlaybackSurahOverride
        ? playbackSurahOverride ?? firstSurahNumber
        : initialSurahIsOnPage
        ? widget.surahNumber
        : firstSurahNumber;
    final verseNumber = usePlaybackSurahOverride
        ? playbackAyahOverride ?? (first['start'] as num).toInt()
        : initialSurahIsOnPage
        ? pendingInitialAyah ?? (first['start'] as num).toInt()
        : (first['start'] as num).toInt();
    if (usePlaybackSurahOverride) {
      _playbackNavigationSurahOverride = null;
      _playbackNavigationAyahOverride = null;
    }
    final rawName = quran.getSurahNameArabic(surahNumber);
    setState(() {
      _pageIndex = index;
      _visibleSurahNumber = surahNumber;
      _surahName = rawName == 'اللهب' ? 'المسد' : rawName;
      _readerCurrentAyah = verseNumber;
      _zoomScale = 1;
      _zoomController.value = Matrix4.identity();
    });
    _cubit.saveReaderPosition(surahNumber, verseNumber);
    // PageView changes are reader-only. Audio-driven seeking/navigation is
    // handled through the playback navigation revision in
    // _handleAudioStateChange, so browsing pages must not seek or replace the
    // active audio session.
    _scheduleControlsHide();
  }

  void _openTafsir(int surahNumber, int verse) {
    if (!_cubit.hasActivePlaybackSession) {
      _cubit.setCurrentPageNumber(verse);
    }
    var globalAyahNumber = verse;
    for (var surah = 1; surah < surahNumber; surah++) {
      globalAyahNumber += quran.getVerseCount(surah);
    }
    final rawName = quran.getSurahNameArabic(surahNumber);
    final surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
          QuranReaderPalette.fromTheme(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder:
          (_) => QuranTafsirSheet(
            surahName: surahName,
            verseNumber: verse,
            verseText: quran.getVerse(surahNumber, verse),
            palette: QuranReaderPalette.fromTheme(context),
            loadTafsir: () => _cubit.getTafsir(globalAyahNumber),
          ),
    );
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _showAyahMenu(int surahNumber, int verse) {
    final rawName = quran.getSurahNameArabic(surahNumber);
    final surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    final verseText = quran.getVerse(surahNumber, verse);
    setState(() {
      _visibleSurahNumber = surahNumber;
      _surahName = surahName;
      _readerCurrentAyah = verse;
    });
    if (!_cubit.hasActivePlaybackSession) {
      _cubit.setSurahInfo(surahNumber, surahName);
      _cubit.setCurrentPageNumber(verse);
    }
    final isBookmarked = _cubit.ayahBookmarks.contains('$surahNumber:$verse');
    final palette = QuranReaderPalette.fromTheme(context);
    showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  AyahActionSheet(
                  surahName: surahName,
                  verseNumber: verse,
                  verseText: verseText,
                  palette: palette,
                  isBookmarked: isBookmarked,
                  onPlayAyahOnly: () {
                    Navigator.pop(sheetContext);
                    unawaited(_cubit.playAyahOnly(surahNumber, verse));
                  },
                  onPlayFromAyah: () {
                    Navigator.pop(sheetContext);
                    unawaited(
                      _cubit.playFromAyahBookmark(surahNumber, verse),
                    );
                  },
                  onTafsir: () {
                    _openTafsir(surahNumber, verse);
                  },
                  onCopy: () {
                    Navigator.pop(sheetContext);
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '$verseText\n$surahName - الآية ${toArabicIndicDigits(verse)}',
                      ),
                    );
                    AppSnackBar.show(message: 'تم نسخ الآية');
                  },
                  onBookmark: () {
                    Navigator.pop(sheetContext);
                    unawaited(_toggleAyahBookmark(surahNumber, verse));
                  },
                  onShare: () {
                    Navigator.pop(sheetContext);
                    unawaited(
                      _cubit.shareAyah(
                        text:
                            '$verseText\n\n$surahName - الآية ${toArabicIndicDigits(verse)}',
                        title: 'آية من سورة $surahName',
                      ),
                    );
                  },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _audioStateSubscription?.cancel();
    _pageController.dispose();
    _zoomController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<QuranCubit, QuranState>(
    builder: (context, state) {
      final palette = QuranReaderPalette.fromTheme(context);
      final bookmarked =
          _cubit.pageBookmarks.contains(_pageIndex + 1);
      final bookmarkPlaybackAyah = _savedPlaybackAyahForCurrentPage();
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: palette.background,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: palette.background,
          systemNavigationBarDividerColor: palette.frame,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: palette.background,
          body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quran.totalPagesCount,
                  onPageChanged: _handlePageChanged,
                  itemBuilder:
                      (context, index) => MushafTextPage(
                        pageNumber: index + 1,
                        zoomController: _zoomController,
                        zoomScale: _zoomScale,
                        fontSize: _fontSize,
                        palette: palette,
                        highlightedSurahNumber:
                            _cubit.hasActivePlaybackSession &&
                                    _cubit.hasReliableCurrentAyah
                                ? _cubit.surahNumber
                                : null,
                        highlightedAyahNumber:
                            _cubit.hasActivePlaybackSession &&
                                    _cubit.hasReliableCurrentAyah
                                ? _cubit.currentAyahNumber
                                : null,
                        bookmarkedAyahKeys: _cubit.ayahBookmarks,
                        onInteractionEnd: _syncZoomScale,
                        onAyahLongPress: _showAyahMenu,
                        onSwipeLeft: () => _turnPage(next: false),
                        onSwipeRight: () => _turnPage(next: true),
                      ),
                ),
              ),
              IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: ReaderControlsOverlay(
                    pageNumber: _pageIndex + 1,
                    pageCount: quran.totalPagesCount,
                    zoomScale: _zoomScale,
                    fontSize: _fontSize,
                    palette: palette,
                    bookmarked: bookmarked,
                    onBookmark: () => unawaited(_toggleCurrentPageBookmark()),
                    onDecrease: () => _changeZoom(_zoomScale - .25),
                    onIncrease: () => _changeZoom(_zoomScale + .25),
                    onFontDecrease: () => _changeFontSize(_fontSize - 1),
                    onFontIncrease: () => _changeFontSize(_fontSize + 1),
                    onPrevious:
                        _pageIndex > 0
                            ? () => _turnPage(next: false)
                            : null,
                    onNext:
                        _pageIndex < quran.totalPagesCount - 1
                            ? () => _turnPage(next: true)
                            : null,
                    onBack: () => Navigator.of(context).maybePop(),
                    audioControls: QuranReaderAudioControls(
                      cubit: _cubit,
                      palette: palette,
                      surahName: _surahName,
                      surahNumber: _visibleSurahNumber,
                      juzNumber: quran.getJuzNumber(
                        _visibleSurahNumber,
                        _readerCurrentAyah,
                      ),
                      bookmarkAyah: bookmarkPlaybackAyah,
                      primaryAction: playIconButton(
                        cubit: _cubit,
                        context: context,
                        backgroundColor: palette.accent,
                        foregroundColor: palette.surface,
                      ),
                    ),
                  ),
                ),
              ),
              if (!_controlsVisible) ...[
                PositionedDirectional(
                  top: 10,
                  end: 18,
                  child: IgnorePointer(
                    child: Text(
                      _surahName,
                      style: TextStyle(
                        color: palette.muted.withValues(alpha: .72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 10,
                  end: 18,
                  child: IgnorePointer(
                    child: Text(
                        'صفحة ${toArabicIndicDigits(_pageIndex + 1)}',
                      style: TextStyle(
                        color: palette.muted.withValues(alpha: .72),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      );
    },
  );
}
