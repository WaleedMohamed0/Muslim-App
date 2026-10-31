import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:untitled8/core/utils/arabic_digits.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_state.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({super.key, required this.surahNumber});
  final int surahNumber;

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  late final QuranCubit _cubit;
  late String _surahName;
  late int _visibleSurahNumber;
  late final PageController _pageController;
  late final TransformationController _zoomController;
  double _zoomScale = 1;
  int _pageIndex = 0;
  bool _controlsVisible = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
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
      builder: (sheetContext) => SingleChildScrollView(
        child: _AyahActionSheet(
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
              ClipboardData(text: '$verseText\n$surahName - الآية ${toArabicIndicDigits(verse)}'),
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
                text: '$verseText\n\n$surahName - الآية ${toArabicIndicDigits(verse)}',
                title: 'آية من سورة $surahName',
              ),
            );
          },
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
      return Scaffold(
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
                      (context, index) => _MushafTextPage(
                        pageNumber: index + 1,
                        zoomController: _zoomController,
                        zoomScale: _zoomScale,
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
                  child: _ReaderControlsOverlay(
                    surahName: _surahName,
                    surahNumber: _visibleSurahNumber,
                    juzNumber: quran.getJuzNumber(
                      _visibleSurahNumber,
                      _cubit.currentPageNumber,
                    ),
                    pageNumber: _pageIndex + 1,
                    pageCount: quran.totalPagesCount,
                    zoomScale: _zoomScale,
                    palette: palette,
                    bookmarked: bookmarked,
                    onBack: () => Navigator.of(context).maybePop(),
                    onBookmark: () => _cubit.toggleBookmark(_surahName),
                    onDecrease: () => _changeZoom(_zoomScale - .25),
                    onIncrease: () => _changeZoom(_zoomScale + .25),
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
      );
    },
  );
}

class _ReaderControlsOverlay extends StatelessWidget {
  const _ReaderControlsOverlay({
    required this.surahName,
    required this.surahNumber,
    required this.juzNumber,
    required this.pageNumber,
    required this.pageCount,
    required this.zoomScale,
    required this.palette,
    required this.bookmarked,
    required this.onBack,
    required this.onBookmark,
    required this.onDecrease,
    required this.onIncrease,
    required this.onPrevious,
    required this.onNext,
    required this.audioButton,
  });

  final String surahName;
  final int surahNumber;
  final int juzNumber;
  final int pageNumber;
  final int pageCount;
  final double zoomScale;
  final QuranReaderPalette palette;
  final bool bookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Widget audioButton;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Align(
        alignment: AlignmentDirectional.topCenter,
        child: Container(
          padding: EdgeInsetsDirectional.fromSTEB(
            12,
            8,
            12,
            18,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.surface.withValues(alpha: .98),
                palette.surface.withValues(alpha: .82),
                palette.surface.withValues(alpha: 0),
              ],
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                _ReaderIconButton(
                  icon: Icons.arrow_forward_rounded,
                  tooltip: 'رجوع',
                  palette: palette,
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surahName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'سورة ${toArabicIndicDigits(surahNumber)} • الجزء ${toArabicIndicDigits(juzNumber)}',
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                audioButton,
              ],
            ),
          ),
        ),
      ),
      Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: Container(
          padding: EdgeInsetsDirectional.fromSTEB(
            12,
            18,
            12,
            8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                palette.surface.withValues(alpha: .98),
                palette.surface.withValues(alpha: .82),
                palette.surface.withValues(alpha: 0),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _ReaderIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'الصفحة السابقة',
                    palette: palette,
                    onPressed: onPrevious,
                  ),
                  const SizedBox(width: 4),
                  _ReaderIconButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'الصفحة التالية',
                    palette: palette,
                    onPressed: onNext,
                  ),
                  const Spacer(),
                  _ReaderIconButton(
                    icon:
                        bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                    tooltip: 'حفظ موضع القراءة',
                    palette: palette,
                    onPressed: onBookmark,
                  ),
                  const SizedBox(width: 8),
                  _ReaderIconButton(
                    icon: Icons.remove,
                    tooltip: 'تصغير العرض',
                    palette: palette,
                    onPressed: onDecrease,
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 8,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${toArabicIndicDigits((zoomScale * 100).round())}٪',
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _ReaderIconButton(
                    icon: Icons.add,
                    tooltip: 'تكبير العرض',
                    palette: palette,
                    onPressed: onIncrease,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'صفحة ${toArabicIndicDigits(pageNumber)} من ${toArabicIndicDigits(pageCount)}',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ReaderIconButton extends StatelessWidget {
  const _ReaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final QuranReaderPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: palette.surface,
      foregroundColor: palette.text,
      disabledForegroundColor: palette.muted.withValues(alpha: .4),
    ),
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    padding: EdgeInsets.zero,
    icon:
        icon == Icons.arrow_forward_rounded
            ? Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(icon),
            )
            : Icon(icon),
  );
}

class _MushafTextPage extends StatefulWidget {
  const _MushafTextPage({
    required this.pageNumber,
    required this.zoomController,
    required this.zoomScale,
    required this.palette,
    required this.onAyahLongPress,
    required this.onInteractionEnd,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final int pageNumber;
  final TransformationController zoomController;
  final double zoomScale;
  final QuranReaderPalette palette;
  final void Function(int surahNumber, int verseNumber) onAyahLongPress;
  final VoidCallback onInteractionEnd;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  State<_MushafTextPage> createState() => _MushafTextPageState();
}

class _MushafTextPageState extends State<_MushafTextPage> {
  final Map<int, Offset> _pointerStarts = {};
  bool _pointerGestureMoved = false;

  void _onPointerDown(PointerDownEvent event) {
    if (_pointerStarts.isEmpty) _pointerGestureMoved = false;
    _pointerStarts[event.pointer] = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final start = _pointerStarts[event.pointer];
    if (start != null && (event.position - start).distance > 18) {
      _pointerGestureMoved = true;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final pointerCount = _pointerStarts.length;
    final start = _pointerStarts.remove(event.pointer);
    if (start == null ||
        pointerCount != 1 ||
        !_pointerGestureMoved ||
        widget.zoomScale > 1.01) {
      return;
    }

    final delta = event.position - start;
    if (delta.dx.abs() < 56 || delta.dx.abs() < delta.dy.abs() * 1.25) {
      return;
    }
    if (delta.dx < 0) {
      widget.onSwipeLeft();
    } else {
      widget.onSwipeRight();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerStarts.remove(event.pointer);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder:
        (context, constraints) => Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: InteractiveViewer(
            transformationController: widget.zoomController,
            minScale: 1,
            maxScale: 3,
            panEnabled: widget.zoomScale > 1.01,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(28),
            onInteractionEnd: (_) => widget.onInteractionEnd(),
            child: _MushafPageContent(
              pageNumber: widget.pageNumber,
              palette: widget.palette,
              onAyahLongPress: widget.onAyahLongPress,
            ),
          ),
        ),
  );

}

class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent({
    required this.pageNumber,
    required this.palette,
    required this.onAyahLongPress,
  });

  final int pageNumber;
  final QuranReaderPalette palette;
  final void Function(int surahNumber, int verseNumber) onAyahLongPress;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final sections = quran.getPageData(pageNumber).cast<Map>();
      final firstSection = sections.first;
      final firstSurah = (firstSection['surah'] as num).toInt();
      final firstVerse = (firstSection['start'] as num).toInt();
      final juzNumber = quran.getJuzNumber(firstSurah, firstVerse);
      final children = <Widget>[
        _MushafRunningHeader(
          surahName: _arabicSurahName(firstSurah),
          juzNumber: juzNumber,
          palette: palette,
        ),
        const SizedBox(height: 14),
      ];

      for (final section in sections) {
        final surahNumber = (section['surah'] as num).toInt();
        final startVerse = (section['start'] as num).toInt();
        final endVerse = (section['end'] as num).toInt();
        if (startVerse == 1) {
          children.add(
            _SurahPageHeading(
              name: _arabicSurahName(surahNumber),
              number: surahNumber,
              palette: palette,
            ),
          );
          if (surahNumber != 1 && surahNumber != 9) {
            children.add(const SizedBox(height: 8));
            children.add(
              Text(
                quran.basmala,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'QuranFont',
                  fontSize: 22,
                  height: 1.8,
                  color: palette.text,
                ),
              ),
            );
          }
          children.add(const SizedBox(height: 10));
        }

        children.add(
          _PageVerseText(
            surahNumber: surahNumber,
            startVerse: startVerse,
            endVerse: endVerse,
            palette: palette,
            onAyahLongPress: onAyahLongPress,
          ),
        );
      }

      children.add(_MushafPageNumber(pageNumber: pageNumber, palette: palette));

      final horizontalInset = constraints.maxWidth < 380 ? 24.0 : 38.0;
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.frame, width: 1.6),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: palette.frame.withValues(alpha: .6)),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              horizontalInset,
              18,
              horizontalInset,
              16,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: constraints.maxWidth - horizontalInset * 2 - 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

String _arabicSurahName(int surahNumber) {
  final name = quran.getSurahNameArabic(surahNumber);
  return name == 'اللهب' ? 'المسد' : name;
}

class _MushafRunningHeader extends StatelessWidget {
  const _MushafRunningHeader({
    required this.surahName,
    required this.juzNumber,
    required this.palette,
  });

  final String surahName;
  final int juzNumber;
  final QuranReaderPalette palette;

  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.rtl,
    children: [
      Text(
        surahName,
        style: TextStyle(
          color: palette.metadata,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      Text(
        'الجزء ${toArabicIndicDigits(juzNumber)}',
        style: TextStyle(
          color: palette.metadata,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SurahPageHeading extends StatelessWidget {
  const _SurahPageHeading({
    required this.name,
    required this.number,
    required this.palette,
  });

  final String name;
  final int number;
  final QuranReaderPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: palette.frame, width: 1),
      ),
    ),
    child: Text(
      'سُورَةُ $name  •  ${toArabicIndicDigits(number)}',
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        color: palette.metadata,
        fontFamily: 'QuranFont',
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PageVerseText extends StatefulWidget {
  const _PageVerseText({
    required this.surahNumber,
    required this.startVerse,
    required this.endVerse,
    required this.palette,
    required this.onAyahLongPress,
  });

  final int surahNumber;
  final int startVerse;
  final int endVerse;
  final QuranReaderPalette palette;
  final void Function(int surahNumber, int verseNumber) onAyahLongPress;

  @override
  State<_PageVerseText> createState() => _PageVerseTextState();
}

class _PageVerseTextState extends State<_PageVerseText> {
  final Map<String, LongPressGestureRecognizer> _recognizers = {};

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final activeRecognizerKeys = <String>{};
    for (var verse = widget.startVerse; verse <= widget.endVerse; verse++) {
      final verseNumber = verse;
      final key = '${widget.surahNumber}:$verseNumber';
      activeRecognizerKeys.add(key);
      final recognizer = _recognizers.putIfAbsent(
        key,
        () => LongPressGestureRecognizer(debugOwner: this),
      );
      recognizer.onLongPress =
          () => widget.onAyahLongPress(widget.surahNumber, verseNumber);
      spans.add(
        TextSpan(
          text: quran.getVerse(widget.surahNumber, verseNumber),
          recognizer: recognizer,
        ),
      );
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress:
                () => widget.onAyahLongPress(
                  widget.surahNumber,
                  verseNumber,
                ),
            child: _VerseMarker(number: verseNumber, palette: widget.palette),
          ),
        ),
      );
      spans.add(
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(width: 5),
        ),
      );
    }
    final staleKeys =
        _recognizers.keys
            .where((key) => !activeRecognizerKeys.contains(key))
            .toList();
    for (final key in staleKeys) {
      _recognizers.remove(key)?.dispose();
    }
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      text: TextSpan(
        style: TextStyle(
          color: widget.palette.text,
          fontFamily: 'QuranFont',
          fontSize: 22,
          height: 1.95,
        ),
        children: spans,
      ),
    );
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }
}

class _VerseMarker extends StatelessWidget {
  const _VerseMarker({required this.number, required this.palette});

  final int number;
  final QuranReaderPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    width: 27,
    height: 27,
    alignment: Alignment.center,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: palette.ornament, width: 1),
      color: palette.highlight,
    ),
    child: Text(
      toArabicIndicDigits(number),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        color: palette.text,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MushafPageNumber extends StatelessWidget {
  const _MushafPageNumber({required this.pageNumber, required this.palette});

  final int pageNumber;
  final QuranReaderPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 5),
    decoration: BoxDecoration(
      border: Border.all(color: palette.ornament),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      toArabicIndicDigits(pageNumber),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        color: palette.metadata,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}


class QuranReaderPalette {
  const QuranReaderPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.highlight,
    required this.frame,
    required this.ornament,
    required this.metadata,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color accent;
  final Color highlight;
  final Color frame;
  final Color ornament;
  final Color metadata;

  static QuranReaderPalette fromTheme(BuildContext context) {
    final appTheme = Theme.of(context);
    final appColors = appTheme.colorScheme;
    final isDark = appTheme.brightness == Brightness.dark;
    return QuranReaderPalette(
      background: appTheme.scaffoldBackgroundColor,
      surface: isDark ? appColors.surfaceContainerHigh : appColors.surface,
      text: appColors.onSurface,
      muted: appColors.onSurfaceVariant,
      accent: appColors.primary,
      highlight: appColors.primary.withValues(alpha: isDark ? .2 : .12),
      frame: appColors.outlineVariant,
      ornament: isDark ? const Color(0xFFC9B482) : const Color(0xFF80633A),
      metadata: appColors.onSurfaceVariant,
    );
  }
}

class _AyahActionSheet extends StatelessWidget {
  const _AyahActionSheet({
    required this.surahName,
    required this.verseNumber,
    required this.verseText,
    required this.palette,
    required this.isBookmarked,
    required this.onTafsir,
    required this.onCopy,
    required this.onBookmark,
    required this.onShare,
  });

  final String surahName;
  final int verseNumber;
  final String verseText;
  final QuranReaderPalette palette;
  final bool isBookmarked;
  final VoidCallback onTafsir;
  final VoidCallback onCopy;
  final VoidCallback onBookmark;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$surahName • الآية ${toArabicIndicDigits(verseNumber)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            verseText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'QuranFont',
              color: palette.text,
              fontSize: 22,
              height: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AyahActionTile(
          icon: Icons.menu_book_rounded,
          label: 'التفسير',
          color: palette.text,
          onTap: onTafsir,
        ),
        _AyahActionTile(
          icon: Icons.copy_rounded,
          label: 'نسخ الآية',
          color: palette.text,
          onTap: onCopy,
        ),
        _AyahActionTile(
          icon:
              isBookmarked
                  ? Icons.bookmark_remove_outlined
                  : Icons.bookmark_add_outlined,
          label: isBookmarked ? 'إزالة العلامة' : 'حفظ كعلامة',
          color: palette.text,
          onTap: onBookmark,
        ),
        _AyahActionTile(
          icon: Icons.share_outlined,
          label: 'مشاركة',
          color: palette.text,
          onTap: onShare,
        ),
      ],
    ),
  );
}

class _AyahActionTile extends StatelessWidget {
  const _AyahActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: color),
    title: Text(
      label,
      textAlign: TextAlign.start,
      style: TextStyle(color: color),
    ),
    onTap: onTap,
  );
}

class QuranTafsirSheet extends StatefulWidget {
  const QuranTafsirSheet({
    super.key,
    required this.surahName,
    required this.verseNumber,
    required this.verseText,
    required this.palette,
    required this.loadTafsir,
  });

  final String surahName;
  final int verseNumber;
  final String verseText;
  final QuranReaderPalette palette;
  final Future<String> Function() loadTafsir;

  @override
  State<QuranTafsirSheet> createState() => _QuranTafsirSheetState();
}

class _QuranTafsirSheetState extends State<QuranTafsirSheet> {
  late Future<String> _tafsir;

  @override
  void initState() {
    super.initState();
    _tafsir = widget.loadTafsir();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .46,
      maxChildSize: .96,
      builder:
          (context, scrollController) => SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 24),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsetsDirectional.fromSTEB(22, 8, 22, 24),
              children: [
                Text(
                  'تفسير الآية',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.surahName} • الآية ${toArabicIndicDigits(widget.verseNumber)}',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    widget.verseText,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'QuranFont',
                      fontSize: 23,
                      height: 1.9,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'التفسير الميسر',
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _tafsir,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return SizedBox(
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: palette.accent,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تعذر تحميل التفسير. تحقق من الاتصال وحاول مجددًا.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: palette.text),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed:
                                  () => setState(
                                    () => _tafsir = widget.loadTafsir(),
                                  ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة المحاولة'),
                              style: TextButton.styleFrom(
                                foregroundColor: palette.accent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Text(
                      snapshot.data!,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        height: 1.9,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}
