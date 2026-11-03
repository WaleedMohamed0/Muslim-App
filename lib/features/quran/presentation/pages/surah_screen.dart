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
import 'package:untitled8/features/quran/presentation/widgets/quran_audio_mini_player.dart';
import 'package:untitled8/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:untitled8/features/quran/presentation/widgets/quran_reader_sheets.dart';
import 'package:untitled8/features/quran/presentation/widgets/reader_controls_overlay.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({super.key, required this.surahNumber});
  final int surahNumber;

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
  double _zoomScale = 1;
  double _fontSize = 19;
  bool _fontSizeChangedBeforeRestore = false;
  int _pageIndex = 0;
  bool _controlsVisible = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreFontSizePreference());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _cubit = context.read<QuranCubit>();
    final bookmarkedVerse =
        _cubit.bookmark?.surahNumber == widget.surahNumber
            ? _cubit.bookmark!.pageNumber
                .clamp(1, quran.getVerseCount(widget.surahNumber))
                .toInt()
            : 1;
    _visibleSurahNumber = widget.surahNumber;
    final rawName = quran.getSurahNameArabic(_visibleSurahNumber);
    _surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    _pageIndex = quran.getPageNumber(widget.surahNumber, bookmarkedVerse) - 1;
    _pageController = PageController(initialPage: _pageIndex);
    _zoomController = TransformationController();
    _cubit.setSurahInfo(widget.surahNumber, _surahName);
    _cubit.setCurrentPageNumber(bookmarkedVerse);
    _scheduleControlsHide();
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
    final surahNumber = (first['surah'] as num).toInt();
    final verseNumber = (first['start'] as num).toInt();
    final rawName = quran.getSurahNameArabic(surahNumber);
    setState(() {
      _pageIndex = index;
      _visibleSurahNumber = surahNumber;
      _surahName = rawName == 'اللهب' ? 'المسد' : rawName;
      _zoomScale = 1;
      _zoomController.value = Matrix4.identity();
    });
    unawaited(
      _cubit.selectSurah(
        surahNumber,
        _surahName,
        online: _cubit.isOnline,
      ),
    );
    _cubit.setCurrentPageNumber(verseNumber);
    _scheduleControlsHide();
  }

  void _openTafsir(int surahNumber, int verse) {
    _cubit.setCurrentPageNumber(verse);
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
    });
    _cubit.setSurahInfo(surahNumber, surahName);
    _cubit.setCurrentPageNumber(verse);
    final isBookmarked =
        _cubit.bookmark?.surahNumber == surahNumber &&
        _cubit.bookmark?.pageNumber == verse;
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
                  onTafsir: () {
                    Navigator.pop(sheetContext);
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
                    _cubit.toggleBookmark(surahName);
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
            const QuranAudioMiniPlayer(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
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
          _cubit.bookmark?.surahNumber == _visibleSurahNumber &&
          _cubit.bookmark?.pageNumber == _cubit.currentPageNumber;
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
                    surahName: _surahName,
                    surahNumber: _visibleSurahNumber,
                    juzNumber: quran.getJuzNumber(
                      _visibleSurahNumber,
                      _cubit.currentPageNumber,
                    ),
                    pageNumber: _pageIndex + 1,
                    pageCount: quran.totalPagesCount,
                    zoomScale: _zoomScale,
                    fontSize: _fontSize,
                    palette: palette,
                    bookmarked: bookmarked,
                    onBack: () => Navigator.of(context).maybePop(),
                    onBookmark: () => _cubit.toggleBookmark(_surahName),
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
                    audioButton: playIconButton(
                      cubit: _cubit,
                      surahNumber: _visibleSurahNumber,
                      context: context,
                      backgroundColor: palette.surface,
                      foregroundColor: palette.text,
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
