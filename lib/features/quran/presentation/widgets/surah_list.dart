import 'package:flutter/material.dart';
import 'package:quran/quran.dart';
import 'package:untitled8/core/theme/app_theme.dart';

import '../pages/surah_screen.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../cubit/quran_cubit.dart';
import 'surah_list_tile.dart';

class SurahList extends StatelessWidget {
  const SurahList({super.key, required this.cubit, required this.online});
  final QuranCubit cubit;
  final bool online;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.xl,
      AppSpacing.xs,
      AppSpacing.xl,
      AppSpacing.md,
    ),
    itemCount: 114,
    itemBuilder: (context, index) {
      final number = index + 1;
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
          if (context.mounted)
            navigateTo(context, SurahScreen(surahNumber: number));
        },
      );
    },
    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
  );
}
