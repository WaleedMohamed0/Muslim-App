import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/khatmah/presentation/cubit/khatmah_cubit.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';
import 'package:muslim/features/quran/presentation/controllers/surah_reader_controller.dart';
import 'package:muslim/features/quran/data/data_sources/mushaf_long_press_hint_preferences.dart';
import 'package:muslim/features/quran/data/data_sources/mushaf_zoom_hint_preferences.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:muslim/features/quran/presentation/widgets/surah_reader_action_sheets.dart';
import 'package:muslim/features/quran/presentation/widgets/surah_reader_view.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.initialPageNumber,
    this.highlightAyah = false,
    this.trackKhatmahProgress = false,
    this.saveGeneralCheckpoint = true,
    this.onPageRead,
    this.minimumPageNumber,
    this.maximumPageNumber,
  });

  final int surahNumber;
  final int? initialAyah;
  final int? initialPageNumber;
  final bool highlightAyah;
  final bool trackKhatmahProgress;
  final bool saveGeneralCheckpoint;
  final void Function(int page, int surah, int ayah)? onPageRead;
  final int? minimumPageNumber;
  final int? maximumPageNumber;

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  late final QuranCubit _cubit;
  late final SurahReaderController _reader;
  String? _lastSystemUiStyleSignature;
  late bool _searchHighlightActive;
  Timer? _searchHighlightTimer;
  bool _showLongPressHint = false;
  bool _showZoomHint = false;
  bool _zoomHintPending = false;
  Timer? _zoomHintTimer;
  final MushafLongPressHintPreferences _hintPreferences =
      const MushafLongPressHintPreferences();
  final MushafZoomHintPreferences _zoomHintPreferences =
      const MushafZoomHintPreferences();

  @override
  void initState() {
    super.initState();
    _searchHighlightActive = widget.highlightAyah;
    if (_searchHighlightActive) {
      _searchHighlightTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _searchHighlightActive = false);
      });
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _cubit = context.read<QuranCubit>();
    unawaited(_loadHints());
    _reader = SurahReaderController(
      cubit: _cubit,
      initialSurah: widget.surahNumber,
      initialAyah: widget.initialAyah,
      initialPageNumber: widget.initialPageNumber,
      saveGeneralCheckpoint: widget.saveGeneralCheckpoint,
      minimumPageNumber: widget.minimumPageNumber,
      maximumPageNumber: widget.maximumPageNumber,
      onPageRead: widget.trackKhatmahProgress
          ? (page, surah, ayah) => context.read<KhatmahCubit>().recordReadingPosition(page: page, surah: surah, ayah: ayah)
          : widget.onPageRead,
    )..addListener(_handleReaderChanged);
    if (widget.trackKhatmahProgress) {
      final initialAyah = widget.initialAyah ?? 1;
      unawaited(context.read<KhatmahCubit>().recordReadingPosition(
        page: MushafLineLayoutData.pageNumber(widget.surahNumber, initialAyah),
        surah: widget.surahNumber,
        ayah: initialAyah,
      ));
    }
  }

  Future<void> _loadHints() async {
    final longPressWasShown = await _hintPreferences.hasBeenShown();
    final zoomWasShown = await _zoomHintPreferences.hasBeenShown();
    if (!mounted) return;

    if (!longPressWasShown) {
      setState(() {
        _showLongPressHint = true;
        _zoomHintPending = !zoomWasShown;
      });
      unawaited(_hintPreferences.markShown());
      return;
    }

    if (!zoomWasShown) _showZoomHintNow();
  }

  void _showZoomHintNow() {
    if (!mounted) return;
    setState(() {
      _showZoomHint = true;
      _zoomHintPending = false;
    });
    unawaited(_zoomHintPreferences.markShown());
    _zoomHintTimer = Timer(const Duration(seconds: 5), _dismissZoomHint);
  }

  void _dismissZoomHint() {
    _zoomHintTimer?.cancel();
    if (!_showZoomHint) return;
    setState(() => _showZoomHint = false);
  }

  void _dismissLongPressHint() {
    if (!_showLongPressHint) return;
    final showZoomNext = _zoomHintPending;
    setState(() {
      _showLongPressHint = false;
      _zoomHintPending = false;
    });
    unawaited(_hintPreferences.markShown());
    if (showZoomNext) unawaited(_showZoomHintAfterLongPress());
  }

  Future<void> _showZoomHintAfterLongPress() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) _showZoomHintNow();
  }

  void _handleReaderChanged() {
    if (mounted) setState(() {});
  }

  String _surahNameForConfirmation(int surahNumber) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!isArabic) return quran.getSurahNameEnglish(surahNumber);
    final name = quran.getSurahNameArabic(surahNumber);
    return name == 'اللهب' ? 'المسد' : name;
  }

  Future<void> _toggleCurrentPageBookmark() async {
    final surahNumber = await _reader.togglePageBookmark();
    if (surahNumber == null || !mounted) return;
    _showBookmarkConfirmation(surahNumber);
  }

  Future<void> _toggleAyahBookmark(int surahNumber, int verseNumber) async {
    final savedSurah = await _reader.toggleAyahBookmark(
      surahNumber,
      verseNumber,
    );
    if (savedSurah == null || !mounted) return;
    _showBookmarkConfirmation(savedSurah);
  }

  void _showBookmarkConfirmation(int surahNumber) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final surahName = _surahNameForConfirmation(surahNumber);
    AppSnackBar.show(
      message:
          isArabic
              ? 'تم حفظ سورة $surahName في العلامات المرجعية'
              : 'Surah $surahName has been saved to bookmarks.',
      success: true,
    );
  }

  void _openTafsir(int surahNumber, int verseNumber) {
    SurahReaderActionSheets.showTafsir(
      context: context,
      cubit: _cubit,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
    );
  }

  void _showAyahMenu(int surahNumber, int verseNumber) {
    _reader.selectAyah(surahNumber, verseNumber);
    SurahReaderActionSheets.showAyahActions(
      context: context,
      cubit: _cubit,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      onTafsir: () => _openTafsir(surahNumber, verseNumber),
      onBookmark:
          () => unawaited(_toggleAyahBookmark(surahNumber, verseNumber)),
    );
  }

  @override
  void dispose() {
    _reader
      ..removeListener(_handleReaderChanged)
      ..dispose();
    _searchHighlightTimer?.cancel();
    _zoomHintTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<QuranCubit, QuranState>(
    builder: (context, state) {
      final palette = QuranReaderPalette.fromTheme(context);
      final statusBarColor = palette.background;
      final navigationBarColor = _reader.controlsVisible
          ? palette.surface
          : palette.background;
      final useLightStatusIcons = statusBarColor.computeLuminance() < .5;
      final useLightNavigationIcons =
          navigationBarColor.computeLuminance() < .5;
      final systemUiStyle = SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness:
            useLightStatusIcons ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            useLightStatusIcons ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarDividerColor: navigationBarColor,
        systemNavigationBarIconBrightness:
            useLightNavigationIcons ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      );
      final styleSignature =
          '${statusBarColor.toARGB32()}:${navigationBarColor.toARGB32()}:'
          '$useLightStatusIcons:$useLightNavigationIcons';
      if (_lastSystemUiStyleSignature != styleSignature) {
        _lastSystemUiStyleSignature = styleSignature;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) SystemChrome.setSystemUIOverlayStyle(systemUiStyle);
        });
      }

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiStyle,
        child: SurahReaderView(
          cubit: _cubit,
          pageController: _reader.pageController,
          zoomController: _reader.zoomController,
          pageIndex: _reader.pageIndex,
          zoomScale: _reader.zoomScale,
          controlsVisible: _reader.controlsVisible,
          bookmarked: _reader.isCurrentPageBookmarked,
          bookmarkAyah: _reader.bookmarkAyahForPlayback,
          surahName: _reader.surahName,
          surahNumber: _reader.visibleSurahNumber,
          currentAyah: _reader.currentAyah,
          searchHighlightSurah: _searchHighlightActive ? widget.surahNumber : null,
          searchHighlightAyah: _searchHighlightActive ? widget.initialAyah : null,
          palette: palette,
          showLongPressHint: _showLongPressHint,
          onDismissLongPressHint: _dismissLongPressHint,
          showZoomHint: _showZoomHint,
          onDismissZoomHint: _dismissZoomHint,
          onToggleControls: _reader.toggleControls,
          onBookmark: () => unawaited(_toggleCurrentPageBookmark()),
          onPrevious:
              _reader.isFirstPage ? null : () => _reader.turnPage(next: false),
          onNext:
              _reader.isLastPage ? null : () => _reader.turnPage(next: true),
          onBack: () => Navigator.of(context).maybePop(),
          onOpenPageSlider: () => _showPageSlider(context, palette),
          onPageChanged:
              (index) => _reader.handlePageChanged(index, widget.surahNumber),
          onInteractionEnd: _reader.syncZoomScale,
          onAyahLongPress: _showAyahMenu,
          onSwipeLeft: () => _reader.turnPage(next: false),
          onSwipeRight: () => _reader.turnPage(next: true),
        ),
      );
    },
  );

  void _showPageSlider(BuildContext context, QuranReaderPalette palette) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        var selectedPage = _reader.pageNumber;
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الانتقال إلى صفحة',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'صفحة ${toArabicIndicDigits(selectedPage)} من ${toArabicIndicDigits(quran.totalPagesCount)}',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    min: 1,
                    max: quran.totalPagesCount.toDouble(),
                    divisions: quran.totalPagesCount - 1,
                    value: selectedPage.toDouble(),
                    activeColor: palette.accent,
                    inactiveColor: palette.muted.withValues(alpha: .25),
                    onChanged: (value) {
                      final page = value.round().clamp(1, quran.totalPagesCount);
                      setSheetState(() => selectedPage = page);
                      _reader.scrubToPage(page);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
