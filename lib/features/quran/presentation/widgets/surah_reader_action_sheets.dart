import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_sheets.dart';

/// Builds the reader's Tafsir and Ayah action sheets.
abstract final class SurahReaderActionSheets {
  static void showTafsir({
    required BuildContext context,
    required QuranCubit cubit,
    required int surahNumber,
    required int verseNumber,
  }) {
    if (!cubit.hasActivePlaybackSession) {
      cubit.setCurrentPageNumber(verseNumber);
    }
    final globalAyahNumber = _globalAyahNumber(surahNumber, verseNumber);
    final surahName = _surahName(surahNumber);
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
      builder:
          (_) => QuranTafsirSheet(
            surahName: surahName,
            verseNumber: verseNumber,
            verseText: UthmaniQuranText.getVerse(surahNumber, verseNumber),
            palette: palette,
            loadTafsir: () => cubit.getTafsir(globalAyahNumber),
          ),
    );
  }

  static void showAyahActions({
    required BuildContext context,
    required QuranCubit cubit,
    required int surahNumber,
    required int verseNumber,
    required VoidCallback onTafsir,
    required VoidCallback onBookmark,
  }) {
    final surahName = _surahName(surahNumber);
    final verseText = UthmaniQuranText.getVerse(surahNumber, verseNumber);
    final isBookmarked = cubit.ayahBookmarks.contains(
      '$surahNumber:$verseNumber',
    );
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
      builder:
          (sheetContext) => ConstrainedBox(
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
                        verseNumber: verseNumber,
                        verseText: verseText,
                        palette: palette,
                        isBookmarked: isBookmarked,
                        onPlayAyahOnly: () {
                          Navigator.pop(sheetContext);
                          unawaited(
                            cubit.playAyahOnly(surahNumber, verseNumber),
                          );
                        },
                        onPlayFromAyah: () {
                          Navigator.pop(sheetContext);
                          unawaited(
                            cubit.playFromAyahBookmark(
                              surahNumber,
                              verseNumber,
                            ),
                          );
                        },
                        onTafsir: onTafsir,
                        onCopy: () {
                          Navigator.pop(sheetContext);
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '$verseText\n$surahName - الآية ${toArabicIndicDigits(verseNumber)}',
                            ),
                          );
                          AppSnackBar.show(message: 'تم نسخ الآية');
                        },
                        onBookmark: () {
                          Navigator.pop(sheetContext);
                          onBookmark();
                        },
                        onShare: () {
                          Navigator.pop(sheetContext);
                          unawaited(
                            cubit.shareAyah(
                              text:
                                  '$verseText\n\n$surahName - الآية ${toArabicIndicDigits(verseNumber)}',
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

  static int _globalAyahNumber(int surahNumber, int verseNumber) {
    var globalAyahNumber = verseNumber;
    for (var surah = 1; surah < surahNumber; surah++) {
      globalAyahNumber += quran.getVerseCount(surah);
    }
    return globalAyahNumber;
  }

  static String _surahName(int surahNumber) {
    final name = UthmaniQuranText.getSurahName(surahNumber);
    return name == 'اللهب' ? 'المسد' : name;
  }
}
