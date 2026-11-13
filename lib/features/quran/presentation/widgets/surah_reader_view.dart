import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/widgets/mushaf_text_page.dart';
import 'package:muslim/features/quran/presentation/widgets/mushaf_long_press_hint.dart';
import 'package:muslim/features/quran/presentation/widgets/mushaf_zoom_hint.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_audio_controls.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:muslim/features/quran/presentation/widgets/reader_controls_overlay.dart';

/// Renders the Mushaf page and its reader controls without owning reader state.
class SurahReaderView extends StatelessWidget {
  const SurahReaderView({
    super.key,
    required this.cubit,
    required this.pageController,
    required this.zoomController,
    required this.pageIndex,
    required this.zoomScale,
    required this.controlsVisible,
    required this.bookmarked,
    required this.bookmarkAyah,
    required this.surahName,
    required this.surahNumber,
    required this.currentAyah,
    this.searchHighlightSurah,
    this.searchHighlightAyah,
    required this.palette,
    this.showLongPressHint = false,
    this.onDismissLongPressHint,
    this.showZoomHint = false,
    this.onDismissZoomHint,
    required this.onToggleControls,
    required this.onBookmark,
    required this.onPrevious,
    required this.onNext,
    required this.onBack,
    required this.onOpenPageSlider,
    required this.onPageChanged,
    required this.onInteractionEnd,
    required this.onAyahLongPress,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final QuranCubit cubit;
  final PageController pageController;
  final TransformationController zoomController;
  final int pageIndex;
  final double zoomScale;
  final bool controlsVisible;
  final bool bookmarked;
  final int? bookmarkAyah;
  final String surahName;
  final int surahNumber;
  final int currentAyah;
  final int? searchHighlightSurah;
  final int? searchHighlightAyah;
  final QuranReaderPalette palette;
  final bool showLongPressHint;
  final VoidCallback? onDismissLongPressHint;
  final bool showZoomHint;
  final VoidCallback? onDismissZoomHint;
  final VoidCallback onToggleControls;
  final VoidCallback onBookmark;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onBack;
  final VoidCallback onOpenPageSlider;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onInteractionEnd;
  final void Function(int surahNumber, int verseNumber) onAyahLongPress;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  Widget build(BuildContext context) {
    final pageNumber = pageIndex + 1;
    return Scaffold(
      backgroundColor: palette.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      reverseDuration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -.08),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: showLongPressHint
                          ? Padding(
                            key: const ValueKey('mushaf-long-press-hint-wrap'),
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              56,
                              16,
                              12,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 440),
                                child: MushafLongPressHint(
                                  key: const ValueKey('mushaf-long-press-hint'),
                                  palette: palette,
                                  onDismiss: onDismissLongPressHint ?? () {},
                                ),
                              ),
                            ),
                          )
                          : const SizedBox.shrink(
                              key: ValueKey('mushaf-long-press-hint-hidden'),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: PageView.builder(
                        controller: pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: quran.totalPagesCount,
                        onPageChanged: onPageChanged,
                        itemBuilder:
                            (context, index) => MushafTextPage(
                      pageNumber: index + 1,
                      zoomController: zoomController,
                      zoomScale: zoomScale,
                      palette: palette,
                      highlightedSurahNumber: searchHighlightAyah != null
                          ? searchHighlightSurah
                          :
                          cubit.hasActivePlaybackSession &&
                                  cubit.hasReliableCurrentAyah
                              ? cubit.surahNumber
                              : null,
                      highlightedAyahNumber: searchHighlightAyah != null
                          ? searchHighlightAyah
                          :
                          cubit.hasActivePlaybackSession &&
                                  cubit.hasReliableCurrentAyah
                              ? cubit.currentAyahNumber
                              : null,
                      bookmarkedAyahKeys: cubit.ayahBookmarks,
                      onInteractionEnd: onInteractionEnd,
                      onAyahLongPress: onAyahLongPress,
                      onSwipeLeft: onSwipeLeft,
                      onSwipeRight: onSwipeRight,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            IgnorePointer(
              ignoring: !controlsVisible,
              child: AnimatedOpacity(
                opacity: controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: ReaderControlsOverlay(
                  pageNumber: pageNumber,
                  pageCount: quran.totalPagesCount,
                  palette: palette,
                  bookmarked: bookmarked,
                  onBookmark: onBookmark,
                  onPrevious: onPrevious,
                  onNext: onNext,
                  onBack: onBack,
                  onOpenPageSlider: onOpenPageSlider,
                  audioControls: QuranReaderAudioControls(
                    cubit: cubit,
                    palette: palette,
                    surahName: surahName,
                    surahNumber: surahNumber,
                    juzNumber: quran.getJuzNumber(surahNumber, currentAyah),
                    bookmarkAyah: bookmarkAyah,
                    primaryAction: playIconButton(
                      cubit: cubit,
                      context: context,
                      backgroundColor: palette.accent,
                      foregroundColor: palette.surface,
                    ),
                  ),
                ),
              ),
            ),
            if (!controlsVisible)
              PositionedDirectional(
                bottom: 10,
                end: 18,
                child: IgnorePointer(
                  child: Text(
                    'صفحة ${toArabicIndicDigits(pageNumber)}',
                    style: TextStyle(
                      color: palette.muted.withValues(alpha: .72),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            if (showZoomHint)
              PositionedDirectional(
                top: 12,
                start: 16,
                end: 16,
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: MushafZoomHint(
                        palette: palette,
                        onDismiss: onDismissZoomHint ?? () {},
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
