import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_download_button.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_playback_progress.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reciter_avatar.dart';

class QuranAudioMiniPlayerCard extends StatelessWidget {
  const QuranAudioMiniPlayerCard({
    super.key,
    required this.cubit,
    required this.palette,
    this.onTap,
  });

  final QuranCubit cubit;
  final QuranReaderPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reciter = cubit.displayReciter;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isBusy = cubit.isAudioLoading;
    final isPlaying = cubit.isPlaying;
    final ayahLabel = toArabicIndicDigits(cubit.currentAyahNumber);
    final details = cubit.hasReliableCurrentAyah
        ? 'سورة ${cubit.surahName}  ·  الآية $ayahLabel من ' +
              toArabicIndicDigits(cubit.currentSurahVerseCount)
        : 'سورة ${cubit.surahName}  ·  توقيت الآية غير متاح';

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(12, 5, 12, 5),
      child: Material(
        color: palette.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(11, 7, 7, 7),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // The shared player can be hosted in a fixed-height panel or
                  // a short bottom sheet. Keep the controls intact and drop
                  // the optional scrubber only when its measured space is
                  // insufficient.
                  final hasProgressSpace =
                      !constraints.maxHeight.isFinite ||
                      constraints.maxHeight >= 82;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          QuranReciterAvatar(reciter: reciter, size: 42),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reciter.displayName(arabic: isArabic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  details,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _MiniPlayerIconButton(
                            tooltip: 'السورة التالية',
                            color: palette.muted,
                            icon: Icons.skip_next_rounded,
                            onPressed: cubit.previousSurah,
                          ),
                          _PlayPauseButton(
                            palette: palette,
                            isBusy: isBusy,
                            isPlaying: isPlaying,
                            onPressed: cubit.togglePlay,
                          ),
                          _MiniPlayerIconButton(
                            tooltip: 'السورة السابقة',
                            color: palette.muted,
                            icon: Icons.skip_previous_rounded,
                            onPressed: cubit.nextSurah,
                          ),
                          _MiniPlayerIconButton(
                            tooltip: 'إيقاف التلاوة',
                            color: palette.muted,
                            icon: Icons.close_rounded,
                            onPressed: cubit.changeQuranSoundActive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          QuranDownloadButton(
                            cubit: cubit,
                            palette: palette,
                            size: 34,
                          ),
                          if (hasProgressSpace && !isBusy) ...[
                            const SizedBox(width: 5),
                            Expanded(
                              child: QuranPlaybackProgress(
                                cubit: cubit,
                                palette: palette,
                              ),
                            ),
                          ] else
                            const Spacer(),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerIconButton extends StatelessWidget {
  const _MiniPlayerIconButton({
    required this.tooltip,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Color color;
  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    color: color,
    iconSize: 19,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    visualDensity: VisualDensity.compact,
    icon: Icon(icon),
  );
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.palette,
    required this.isBusy,
    required this.isPlaying,
    required this.onPressed,
  });

  final QuranReaderPalette palette;
  final bool isBusy;
  final bool isPlaying;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: isPlaying ? 'إيقاف مؤقت' : 'تشغيل التلاوة',
    child: Material(
      color: palette.accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isBusy ? null : onPressed,
        child: SizedBox.square(
          dimension: 40,
          child: Center(
            child:
                isBusy
                    ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.surface,
                      ),
                    )
                    : Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: palette.surface,
                      size: 23,
                    ),
          ),
        ),
      ),
    ),
  );
}

