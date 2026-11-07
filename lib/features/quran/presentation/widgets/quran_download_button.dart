import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

class QuranDownloadButton extends StatelessWidget {
  const QuranDownloadButton({
    super.key,
    required this.cubit,
    required this.palette,
    this.size = 38,
  });

  final QuranCubit cubit;
  final QuranReaderPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDownloading = cubit.isDownloading;
    final isDownloaded = cubit.isCurrentSurahDownloaded;
    final canDownload = cubit.canDownloadCurrentSurah;
    final icon = isDownloaded
        ? Icons.download_done_rounded
        : cubit.hasCurrentSurahDownloadFailed
            ? Icons.refresh_rounded
            : canDownload
                ? Icons.download_rounded
                : Icons.cloud_off_outlined;
    final tooltip = isDownloading
        ? (isArabic ? 'جارٍ تنزيل السورة' : 'Downloading Surah')
        : isDownloaded
            ? (isArabic ? 'السورة محفوظة دون اتصال' : 'Available offline')
            : cubit.hasCurrentSurahDownloadFailed
                ? (isArabic ? 'إعادة محاولة التنزيل' : 'Retry download')
                : canDownload
                    ? (isArabic ? 'تنزيل السورة' : 'Download Surah')
                    : (isArabic
                        ? 'التنزيل غير متاح لهذا القارئ'
                        : 'Download unavailable for this reciter');

    return IconButton(
      onPressed: !canDownload || isDownloading || isDownloaded
          ? null
          : () => unawaited(cubit.downloadSurahSound()),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: isDownloaded ? palette.accent : palette.muted,
        backgroundColor: palette.background.withValues(alpha: .72),
        disabledForegroundColor: isDownloaded
            ? palette.accent
            : palette.muted.withValues(alpha: .55),
      ),
      icon: isDownloading
          ? SizedBox.square(
              dimension: size * .48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.accent,
              ),
            )
          : Icon(icon, size: 20),
    );
  }
}
