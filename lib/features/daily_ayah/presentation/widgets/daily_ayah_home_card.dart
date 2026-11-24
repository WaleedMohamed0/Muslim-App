import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/features/daily_ayah/data/repositories/daily_ayah_repository.dart';
import 'package:muslim/features/daily_ayah/presentation/pages/daily_ayah_screen.dart';

class DailyAyahHomeCard extends StatelessWidget {
  const DailyAyahHomeCard({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: DailyAyahRepository().getForDate(DateTime.now().toUtc()),
    builder: (context, snapshot) {
      final ayah = snapshot.data;
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 18),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: ayah == null
                ? null
                : () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: '/daily-ayah'),
                      builder: (_) => DailyAyahScreen(ayah: ayah),
                    ),
                  ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    colors.primaryContainer.withValues(alpha: .76),
                    colors.surface,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(AppRadii.tile),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'آية اليوم',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ayah == null
                              ? 'جارٍ تحميل الآية…'
                              : '${ayah.surahName} • ${ayah.ayahNumber}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
