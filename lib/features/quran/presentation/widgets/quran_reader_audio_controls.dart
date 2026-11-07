import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_playback_progress.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_download_button.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reciter_avatar.dart';

/// Reader-specific controls backed by the same Cubit and audio engine as the
/// Mini Player and Android media notification.
class QuranReaderAudioControls extends StatelessWidget {
  const QuranReaderAudioControls({
    super.key,
    required this.cubit,
    required this.palette,
    required this.surahName,
    required this.surahNumber,
    required this.juzNumber,
    this.bookmarkAyah,
    required this.primaryAction,
  });

  final QuranCubit cubit;
  final QuranReaderPalette palette;
  final String surahName;
  final int surahNumber;
  final int juzNumber;
  final int? bookmarkAyah;
  final Widget primaryAction;

  @override
  Widget build(BuildContext context) {
    final cardColor = Color.alphaBlend(
      palette.accent.withValues(alpha: .055),
      palette.background,
    );
    final reciter = cubit.displayReciter;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final verseCount = cubit.currentSurahVerseCount;
    final ayah = verseCount > 0
        ? cubit.currentAyahNumber.clamp(1, verseCount)
        : cubit.currentAyahNumber;

    return Material(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(21),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: palette.frame.withValues(alpha: .8)),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  QuranReciterAvatar(reciter: reciter, size: 37),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reciter.displayName(arabic: isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'سورة $surahName • الآية ${toArabicIndicDigits(ayah)}'
                          '${verseCount > 0 ? ' من ${toArabicIndicDigits(verseCount)}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  _ReaderMetaPill(
                    palette: palette,
                    text: 'ج${toArabicIndicDigits(juzNumber)}',
                  ),
                  const SizedBox(width: 3),
                  QuranDownloadButton(
                    cubit: cubit,
                    palette: palette,
                    size: 34,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (bookmarkAyah != null) ...[
                    _ReaderTransportButton(
                      palette: palette,
                      tooltip: 'تشغيل من العلامة المرجعية',
                      icon: Icons.play_circle_outline_rounded,
                      onPressed: () => unawaited(
                        cubit.playFromAyahBookmark(surahNumber, bookmarkAyah!),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _ReaderTransportButton(
                    palette: palette,
                    tooltip: 'السورة التالية',
                    icon: Icons.skip_next_rounded,
                    onPressed: () => unawaited(cubit.previousSurah()),
                  ),
                  const SizedBox(width: 12),
                  primaryAction,
                  const SizedBox(width: 12),
                  _ReaderTransportButton(
                    palette: palette,
                    tooltip: 'السورة السابقة',
                    icon: Icons.skip_previous_rounded,
                    onPressed: () => unawaited(cubit.nextSurah()),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              QuranPlaybackProgress(
                cubit: cubit,
                palette: palette,
                showTimeLabels: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderMetaPill extends StatelessWidget {
  const _ReaderMetaPill({required this.palette, required this.text});

  final QuranReaderPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(7, 4, 7, 4),
    decoration: BoxDecoration(
      color: palette.background.withValues(alpha: .75),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: palette.muted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ReaderTransportButton extends StatelessWidget {
  const _ReaderTransportButton({
    required this.palette,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final QuranReaderPalette palette;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 38, height: 38),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      foregroundColor: palette.accent,
      backgroundColor: palette.background.withValues(alpha: .72),
    ),
    icon: Icon(icon, size: 20),
  );
}
