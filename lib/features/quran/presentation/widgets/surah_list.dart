import 'package:flutter/material.dart';
import 'package:quran/quran.dart';
import 'package:untitled8/core/theme/app_theme.dart';

import '../pages/surah_screen.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../cubit/quran_cubit.dart';
import 'surah_list_tile.dart';

class SurahList extends StatelessWidget {
  const SurahList({
    super.key,
    required this.cubit,
    required this.online,
    this.searchQuery = '',
  });
  final QuranCubit cubit;
  final bool online;
  final String searchQuery;

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي');

  @override
  Widget build(BuildContext context) {
    final query = _normalize(searchQuery);
    final numbers = List<int>.generate(114, (index) => index + 1).where((number) {
      if (query.isEmpty) return true;
      final rawName = getSurahNameArabic(number);
      final displayName = rawName == 'اللهب' ? 'المسد' : rawName;
      return _normalize(displayName).contains(query) ||
          number.toString().contains(query) ||
          _arabicNumber(number).contains(query);
    }).toList();

    if (numbers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'لا توجد سورة بهذا الاسم',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
    padding: const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.xl,
      AppSpacing.xs,
      AppSpacing.xl,
      AppSpacing.md,
    ),
    itemCount: numbers.length,
    itemBuilder: (context, index) {
      final number = numbers[index];
      final rawName = getSurahNameArabic(number);
      return SurahListTile(
        number: number,
        name: rawName == 'اللهب' ? 'المسد' : rawName,
        verses: getVerseCount(number),
        place: getPlaceOfRevelation(number) == 'Makkah' ? 'مكية' : 'مدنية',
        onTap: () async {
          if (cubit.surahNumber != number) {
            await cubit.selectSurah(number, rawName, online: online);
          }
          if (context.mounted) {
            navigateTo(context, SurahScreen(surahNumber: number));
          }
        },
      );
    },
    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
    );
  }

  String _arabicNumber(int value) => value
      .toString()
      .replaceAll('0', '٠')
      .replaceAll('1', '١')
      .replaceAll('2', '٢')
      .replaceAll('3', '٣')
      .replaceAll('4', '٤')
      .replaceAll('5', '٥')
      .replaceAll('6', '٦')
      .replaceAll('7', '٧')
      .replaceAll('8', '٨')
      .replaceAll('9', '٩');
}
