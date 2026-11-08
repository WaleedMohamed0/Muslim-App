import 'package:flutter/material.dart';
import 'package:muslim/features/tajweed/data/tajweed_lessons.dart';
import 'package:muslim/features/tajweed/presentation/pages/tajweed_lesson_details_screen.dart';
import 'package:muslim/features/tajweed/presentation/widgets/tajweed_lesson_card.dart';

class TajweedLessonsScreen extends StatelessWidget {
  const TajweedLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دروس التَّجْوِيد')),
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: .78),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 40,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رحلتك مع التلاوة المتقنة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'مسار متدرج من الأساسيات إلى أحكام الأداء',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: .9,
                            ),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'المسار التعليمي',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text('ابدأ من المقدمة وتقدم درسًا بعد درس', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            for (var i = 0; i < TajweedLessons.all.length; i++) ...[
              TajweedLessonCard(
                lesson: TajweedLessons.all[i],
                index: i,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    settings: RouteSettings(name: '/tajweed/${i + 1}'),
                    builder: (_) => TajweedLessonDetailsScreen(
                      lesson: TajweedLessons.all[i],
                      index: i,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
