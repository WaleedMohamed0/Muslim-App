import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/pages/juz_surahs_screen.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_audio_mini_player.dart';

class JuzList extends StatelessWidget {
  const JuzList({
    super.key,
    required this.cubit,
    required this.online,
    required this.miniPlayerHeight,
    this.searchQuery = '',
  });

  final QuranCubit cubit;
  final bool online;
  final ValueListenable<double> miniPlayerHeight;
  final String searchQuery;

  static const _arabicOrdinals = [
    'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع',
    'الثامن', 'التاسع', 'العاشر', 'الحادي عشر', 'الثاني عشر', 'الثالث عشر',
    'الرابع عشر', 'الخامس عشر', 'السادس عشر', 'السابع عشر', 'الثامن عشر',
    'التاسع عشر', 'العشرون', 'الحادي والعشرون', 'الثاني والعشرون',
    'الثالث والعشرون', 'الرابع والعشرون', 'الخامس والعشرون', 'السادس والعشرون',
    'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
  ];

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9');

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final query = _normalize(searchQuery);
    final juzNumbers = List<int>.generate(quran.totalJuzCount, (index) => index + 1)
        .where((number) {
          if (query.isEmpty) return true;
          final ranges = quran.getSurahAndVersesFromJuz(number);
          final entries = ranges.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key));
          final start = entries.first;
          final end = entries.last;
          final startName = isArabic
              ? _arabicSurahName(start.key)
              : quran.getSurahNameEnglish(start.key);
          final endName = isArabic
              ? _arabicSurahName(end.key)
              : quran.getSurahNameEnglish(end.key);
          final ordinal = isArabic ? _arabicOrdinals[number - 1] : 'Juz $number';
          final searchable = _normalize(
            '$ordinal $number $startName ${start.value.first} '
            '$endName ${end.value.last}',
          );
          return searchable.contains(query);
        })
        .toList(growable: false);

    if (juzNumbers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            isArabic ? 'لا يوجد جزء يطابق البحث' : 'No matching Juz found',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: miniPlayerHeight,
      builder: (context, playerHeight, _) {
        final playerInset = quranMiniPlayerBottomInset(
          context,
          visible: cubit.quranSoundActive,
          measuredHeight: playerHeight,
        );
        return ListView.separated(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            AppSpacing.md + playerInset,
          ),
          itemCount: juzNumbers.length,
          itemBuilder: (context, index) {
            final number = juzNumbers[index];
            final ranges = quran.getSurahAndVersesFromJuz(number);
            final entries = ranges.entries.toList()
              ..sort((left, right) => left.key.compareTo(right.key));
            final start = entries.first;
            final end = entries.last;
            final title = isArabic
                ? 'الجزء ${_arabicOrdinals[number - 1]}'
                : 'Juz $number';
            final startSurah = isArabic
                ? _arabicSurahName(start.key)
                : quran.getSurahNameEnglish(start.key);
            final endSurah = isArabic
                ? _arabicSurahName(end.key)
                : quran.getSurahNameEnglish(end.key);
            final startAyah = isArabic
                ? toArabicIndicDigits(start.value.first)
                : '${start.value.first}';
            final endAyah = isArabic
                ? toArabicIndicDigits(end.value.last)
                : '${end.value.last}';
            final details = isArabic
                ? 'يبدأ من $startSurah، الآية $startAyah'
                    '\nينتهي عند $endSurah، الآية $endAyah'
                : 'Starts at $startSurah, verse $startAyah'
                    '\nEnds at $endSurah, verse $endAyah';

            return _JuzListTile(
              number: number,
              title: title,
              details: details,
              isArabic: isArabic,
              onTap: () async {
                if (context.mounted) {
                  navigateTo(
                    context,
                    JuzSurahsScreen(
                      juzNumber: number,
                      juzTitle: title,
                      cubit: cubit,
                      online: online,
                    ),
                  );
                }
              },
            );
          },
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
        );
      },
    );
  }

  String _arabicSurahName(int number) {
    final name = quran.getSurahNameArabic(number);
    return name == 'اللهب' ? 'المسد' : name;
  }
}

class _JuzListTile extends StatelessWidget {
  const _JuzListTile({
    required this.number,
    required this.title,
    required this.details,
    required this.isArabic,
    required this.onTap,
  });

  final int number;
  final String title;
  final String details;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isArabic ? toArabicIndicDigits(number) : '$number',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
