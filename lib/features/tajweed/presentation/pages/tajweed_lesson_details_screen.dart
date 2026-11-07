import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';
import 'package:muslim/features/tajweed/domain/entities/tajweed_lesson.dart';

class TajweedLessonDetailsScreen extends StatelessWidget {
  const TajweedLessonDetailsScreen({
    super.key,
    required this.lesson,
    required this.index,
  });

  final TajweedLesson lesson;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(lesson.title)),
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(lesson.icon, size: 38, color: theme.colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الدرس ${index + 1} · ${lesson.level}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lesson.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _LessonSection(
              title: 'الفكرة الأساسية',
              icon: Icons.lightbulb_outline_rounded,
              titleFontSize: 18,
              child: Text(
                lesson.introduction,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
              ),
            ),
            const SizedBox(height: 14),
            _LessonSection(
              title: 'قواعد مهمة',
              icon: Icons.checklist_rounded,
              titleFontSize: 18,
              child: Column(
                children: [
                  for (final rule in lesson.rules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 19,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rule,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _LessonSection(
              title: 'مثال وتطبيق',
              icon: Icons.menu_book_rounded,
              titleFontSize: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lesson.exampleSurahNumber != null &&
                      lesson.exampleAyahNumber != null)
                    _ExampleVerse(lesson: lesson)
                  else
                    Text(lesson.example,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 1.9, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    lesson.reference,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lesson.example.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(lesson.example, style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                  ],
                  if (lesson.exampleSurahNumber != null &&
                      lesson.exampleAyahNumber != null) ...[
                    const SizedBox(height: 14),
                    BlocBuilder<QuranCubit, QuranState>(
                      builder: (context, state) {
                        final cubit = context.read<QuranCubit>();
                        final exampleAudioUrl = cubit.selectedReciter.ayahUrl(
                          lesson.exampleSurahNumber!,
                          lesson.exampleAyahNumber!,
                        );
                        final isExampleSource =
                            exampleAudioUrl != null &&
                            cubit.quranSoundUrl == exampleAudioUrl;
                        final isExampleActive =
                            isExampleSource &&
                            cubit.playbackMode == QuranPlaybackMode.ayahOnly &&
                            cubit.quranSoundActive;
                        final isPlaying = cubit.isPlaying;
                        final isLoading =
                            isExampleActive && cubit.isAudioLoading;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilledButton.icon(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () {
                                        if (isExampleActive && isPlaying) {
                                          cubit.changeQuranSoundActive();
                                        } else {
                                          cubit.playAyahOnly(
                                            lesson.exampleSurahNumber!,
                                            lesson.exampleAyahNumber!,
                                          );
                                        }
                                      },
                              icon: Icon(
                                isPlaying && isExampleActive
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(
                                isLoading
                                    ? 'جارٍ تحميل المثال…'
                                    : isExampleActive && isPlaying
                                    ? 'إيقاف المثال'
                                    : 'استمع إلى المثال',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'استمع إلى التلاوة وطبّق الحكم مع معلّم متقن؛ فالأداء يُتلقى بالمشافهة.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleVerse extends StatelessWidget {
  const _ExampleVerse({required this.lesson});

  final TajweedLesson lesson;

  @override
  Widget build(BuildContext context) {
    final text = UthmaniQuranText.getVerse(
      lesson.exampleSurahNumber!, lesson.exampleAyahNumber!);
    final highlight = lesson.exampleHighlight;
    final start = highlight == null ? -1 : text.indexOf(highlight);
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      height: 1.9, fontSize: 17, fontWeight: FontWeight.w700);
    if (start < 0) return Text('﴿$text﴾', style: style);
    return Text.rich(TextSpan(style: style, children: [
      TextSpan(text: '﴿${text.substring(0, start)}'),
      TextSpan(text: text.substring(start, start + highlight!.length),
        style: style?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).colorScheme.primary)),
      TextSpan(text: '${text.substring(start + highlight.length)}﴾'),
    ]));
  }
}

class _LessonSection extends StatelessWidget {
  const _LessonSection({
    required this.title,
    required this.icon,
    required this.child,
    this.titleFontSize,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final double? titleFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
