import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/widgets/mushaf_text_page.dart';
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
    required this.fontSize,
    required this.zoomScale,
    required this.controlsVisible,
    required this.bookmarked,
    required this.bookmarkAyah,
    required this.surahName,
    required this.surahNumber,
    required this.currentAyah,
    required this.palette,
    required this.onToggleControls,
    required this.onBookmark,
    required this.onFontDecrease,
    required this.onFontIncrease,
    required this.onPrevious,
    required this.onNext,
    required this.onBack,
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
  final double fontSize;
  final double zoomScale;
  final bool controlsVisible;
  final bool bookmarked;
  final int? bookmarkAyah;
  final String surahName;
  final int surahNumber;
  final int currentAyah;
  final QuranReaderPalette palette;
  final VoidCallback onToggleControls;
  final VoidCallback onBookmark;
  final VoidCallback onFontDecrease;
  final VoidCallback onFontIncrease;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onBack;
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
            Directionality(
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
                      fontSize: fontSize,
                      palette: palette,
                      highlightedSurahNumber:
                          cubit.hasActivePlaybackSession &&
                                  cubit.hasReliableCurrentAyah
                              ? cubit.surahNumber
                              : null,
                      highlightedAyahNumber:
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
            IgnorePointer(
              ignoring: !controlsVisible,
              child: AnimatedOpacity(
                opacity: controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: ReaderControlsOverlay(
                  pageNumber: pageNumber,
                  pageCount: quran.totalPagesCount,
                  fontSize: fontSize,
                  palette: palette,
                  bookmarked: bookmarked,
                  onBookmark: onBookmark,
                  onFontDecrease: onFontDecrease,
                  onFontIncrease: onFontIncrease,
                  onPrevious: onPrevious,
                  onNext: onNext,
                  onBack: onBack,
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
          ],
        ),
      ),
    );
  }
}
