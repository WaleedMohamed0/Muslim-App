import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/quran/domain/entities/quran_bookmark.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/pages/surah_screen.dart';

class SavedBookmarksDialog {
  const SavedBookmarksDialog._();

  static Future<void> show(BuildContext context, QuranCubit cubit) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final pageItems = cubit.pageBookmarks.reversed
        .map((pageNumber) {
          final pageData = MushafLineLayoutData.pageData(pageNumber);
          if (pageData.isEmpty) return null;
          final first = pageData.first;
          final surahNumber = (first['surah'] as num).toInt();
          final firstAyah = (first['start'] as num).toInt();
          final rawName = quran.getSurahNameArabic(surahNumber);
          final surahName =
              isArabic
                  ? (rawName == 'اللهب' ? 'المسد' : rawName)
                  : quran.getSurahNameEnglish(surahNumber);
          final pageLabel =
              isArabic ? toArabicIndicDigits(pageNumber) : '$pageNumber';
          return _SavedBookmarkRowData(
            title:
                isArabic
                    ? 'سورة $surahName — الصفحة $pageLabel'
                    : 'Surah $surahName — Page $pageLabel',
            typeLabel: isArabic ? 'صفحة' : 'Page',
            icon: Icons.auto_stories_rounded,
            onTap:
                (dialogContext) => _openSavedPage(
                  context,
                  dialogContext,
                  cubit,
                  surahNumber,
                  firstAyah,
                  pageNumber,
                  rawName == 'اللهب' ? 'المسد' : rawName,
                ),
          );
        })
        .whereType<_SavedBookmarkRowData>()
        .toList(growable: false);

    final ayahItems = cubit.ayahBookmarks
        .map((key) {
          final parts = key.split(':');
          if (parts.length != 2) return null;
          final surahNumber = int.tryParse(parts.first);
          final ayahNumber = int.tryParse(parts.last);
          if (surahNumber == null ||
              ayahNumber == null ||
              surahNumber < 1 ||
              surahNumber > quran.totalSurahCount ||
              ayahNumber < 1 ||
              ayahNumber > quran.getVerseCount(surahNumber)) {
            return null;
          }
          final rawName = quran.getSurahNameArabic(surahNumber);
          final surahName =
              isArabic
                  ? (rawName == 'اللهب' ? 'المسد' : rawName)
                  : quran.getSurahNameEnglish(surahNumber);
          final ayahLabel =
              isArabic ? toArabicIndicDigits(ayahNumber) : '$ayahNumber';
          return _SavedBookmarkRowData(
            title:
                isArabic
                    ? 'سورة $surahName — الآية $ayahLabel'
                    : 'Surah $surahName — Ayah $ayahLabel',
            typeLabel: isArabic ? 'آية' : 'Ayah',
            icon: Icons.menu_book_rounded,
            onTap:
                (dialogContext) => _openSavedAyah(
                  context,
                  dialogContext,
                  cubit,
                  surahNumber,
                  ayahNumber,
                  rawName == 'اللهب' ? 'المسد' : rawName,
                ),
          );
        })
        .whereType<_SavedBookmarkRowData>()
        .toList(growable: false);

    final latestPageBookmark = cubit.bookmark;
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.bookmarks_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isArabic ? 'العلامات المرجعية' : 'Saved bookmarks',
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .62,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (pageItems.isEmpty && ayahItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          isArabic
                              ? 'لا توجد علامات مرجعية محفوظة بعد'
                              : 'No saved bookmarks yet',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    if (pageItems.isNotEmpty) ...[
                      _BookmarkSectionHeading(
                        title: isArabic ? 'الصفحات' : 'Pages',
                        count: pageItems.length,
                        isArabic: isArabic,
                      ),
                      for (final item in pageItems)
                        _SavedBookmarkTile(
                          item: item,
                          onTap: () => item.onTap(dialogContext),
                        ),
                    ],
                    if (ayahItems.isNotEmpty) ...[
                      if (pageItems.isNotEmpty)
                        const SizedBox(height: AppSpacing.md),
                      _BookmarkSectionHeading(
                        title: isArabic ? 'الْآيَات' : 'Ayahs',
                        count: ayahItems.length,
                        isArabic: isArabic,
                      ),
                      for (final item in ayahItems)
                        _SavedBookmarkTile(
                          item: item,
                          onTap: () => item.onTap(dialogContext),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              if (latestPageBookmark != null) ...[
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    unawaited(
                      _playFromBookmark(context, cubit, latestPageBookmark),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(isArabic ? 'تشغيل من العلامة' : 'Play bookmark'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    unawaited(
                      _continueReading(context, cubit, latestPageBookmark),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(isArabic ? 'متابعة القراءة' : 'Continue reading'),
                ),
              ],
            ],
          ),
    );
  }

  static Future<void> _openSavedPage(
    BuildContext context,
    BuildContext dialogContext,
    QuranCubit cubit,
    int surahNumber,
    int firstAyah,
    int pageNumber,
    String surahName,
  ) async {
    Navigator.of(dialogContext).pop();
    await cubit.openAtAyah(
      surahNumber,
      surahName,
      firstAyah,
      online: cubit.isOnline,
    );
    if (!context.mounted) return;
    navigateTo(
      context,
      SurahScreen(
        surahNumber: surahNumber,
        initialAyah: firstAyah,
        initialPageNumber: pageNumber,
      ),
    );
  }

  static Future<void> _openSavedAyah(
    BuildContext context,
    BuildContext dialogContext,
    QuranCubit cubit,
    int surahNumber,
    int ayahNumber,
    String surahName,
  ) async {
    Navigator.of(dialogContext).pop();
    await cubit.openAtAyah(
      surahNumber,
      surahName,
      ayahNumber,
      online: cubit.isOnline,
    );
    if (!context.mounted) return;
    navigateTo(
      context,
      SurahScreen(surahNumber: surahNumber, initialAyah: ayahNumber),
    );
  }

  static Future<void> _continueReading(
    BuildContext context,
    QuranCubit cubit,
    QuranBookmark bookmark,
  ) async {
    final pageEntries = MushafLineLayoutData.pageData(bookmark.pageNumber);
    final firstEntry = pageEntries.first;
    final surahNumber = (firstEntry['surah'] as num).toInt();
    final firstAyah = bookmark.surahNumber == surahNumber
        ? (bookmark.ayahNumber ?? (firstEntry['start'] as num).toInt())
        : (firstEntry['start'] as num).toInt();
    final rawName = quran.getSurahNameArabic(surahNumber);
    final surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    await cubit.selectSurah(surahNumber, surahName, online: cubit.isOnline);
    cubit.setCurrentPageNumber(firstAyah);
    if (!context.mounted) return;
    navigateTo(context, SurahScreen(surahNumber: surahNumber));
  }

  static Future<void> _playFromBookmark(
    BuildContext context,
    QuranCubit cubit,
    QuranBookmark bookmark,
  ) async {
    final pageEntries = MushafLineLayoutData.pageData(bookmark.pageNumber);
    final firstEntry = pageEntries.first;
    final surahNumber = (firstEntry['surah'] as num).toInt();
    final firstAyah = bookmark.surahNumber == surahNumber
        ? (bookmark.ayahNumber ?? (firstEntry['start'] as num).toInt())
        : (firstEntry['start'] as num).toInt();
    await cubit.playFromAyahBookmark(surahNumber, firstAyah);
    if (!context.mounted) return;
    navigateTo(context, SurahScreen(surahNumber: surahNumber));
  }
}

class _SavedBookmarkRowData {
  const _SavedBookmarkRowData({
    required this.title,
    required this.typeLabel,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String typeLabel;
  final IconData icon;
  final ValueChanged<BuildContext> onTap;
}

class _BookmarkSectionHeading extends StatelessWidget {
  const _BookmarkSectionHeading({
    required this.title,
    required this.count,
    required this.isArabic,
  });

  final String title;
  final int count;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 6, 2, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              isArabic ? toArabicIndicDigits(count) : '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedBookmarkTile extends StatelessWidget {
  const _SavedBookmarkTile({required this.item, required this.onTap});

  final _SavedBookmarkRowData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 3, 12, 3),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(item.icon, color: colors.onPrimaryContainer, size: 20),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            item.typeLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
