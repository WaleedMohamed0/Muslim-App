import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/pages/surah_screen.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_audio_mini_player.dart';
import 'package:muslim/features/quran/presentation/widgets/surah_list_tile.dart';

class JuzSurahsScreen extends StatefulWidget {
  const JuzSurahsScreen({
    super.key,
    required this.juzNumber,
    required this.juzTitle,
    required this.cubit,
    required this.online,
  });

  final int juzNumber;
  final String juzTitle;
  final QuranCubit cubit;
  final bool online;

  @override
  State<JuzSurahsScreen> createState() => _JuzSurahsScreenState();
}

class _JuzSurahsScreenState extends State<JuzSurahsScreen> {
  final ValueNotifier<double> _miniPlayerHeight = ValueNotifier(0);

  @override
  void dispose() {
    _miniPlayerHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final ranges = quran.getSurahAndVersesFromJuz(widget.juzNumber);
    final entries = ranges.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return Scaffold(
      appBar: defaultAppBar(context: context, text: widget.juzTitle),
      body: myPanel(
        context: context,
        cubit: widget.cubit,
        onMiniPlayerHeightChanged: (height) {
          if (!mounted || (_miniPlayerHeight.value - height).abs() < .5) {
            return;
          }
          _miniPlayerHeight.value = height;
        },
        screen: SafeArea(
          top: false,
          child: ValueListenableBuilder<double>(
            valueListenable: _miniPlayerHeight,
            builder: (context, playerHeight, _) {
              final playerInset = quranMiniPlayerBottomInset(
                context,
                visible: widget.cubit.quranSoundActive,
                measuredHeight: playerHeight,
              );
              return ListView.separated(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.xl + playerInset,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final surahNumber = entry.key;
                  final firstAyah = entry.value.first;
                  final lastAyah = entry.value.last;
                  final rawArabicName = quran.getSurahNameArabic(surahNumber);
                  final surahName = isArabic
                      ? (rawArabicName == 'اللهب' ? 'المسد' : rawArabicName)
                      : quran.getSurahNameEnglish(surahNumber);
                  final firstLabel = isArabic
                      ? toArabicIndicDigits(firstAyah)
                      : '$firstAyah';
                  final lastLabel = isArabic
                      ? toArabicIndicDigits(lastAyah)
                      : '$lastAyah';
                  final rangeLabel = isArabic
                      ? 'الآيات $firstLabel–$lastLabel'
                      : 'Ayahs $firstLabel–$lastLabel';

                  return SurahListTile(
                    number: surahNumber,
                    name: surahName,
                    verses: lastAyah - firstAyah + 1,
                    place: '',
                    subtitle: rangeLabel,
                    numberLabel: isArabic
                        ? toArabicIndicDigits(surahNumber)
                        : '$surahNumber',
                    onTap: () async {
                      await widget.cubit.openAtAyah(
                        surahNumber,
                        rawArabicName == 'اللهب' ? 'المسد' : rawArabicName,
                        firstAyah,
                        online: widget.online,
                        preservePlayback: true,
                      );
                      if (context.mounted) {
                        navigateTo(
                          context,
                          SurahScreen(
                            surahNumber: surahNumber,
                            initialAyah: firstAyah,
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
          ),
        ),
      ),
    );
  }
}
