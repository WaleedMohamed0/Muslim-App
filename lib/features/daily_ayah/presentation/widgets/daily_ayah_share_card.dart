import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/app/presentation/widgets/notification_logo.dart';
import 'package:muslim/features/daily_ayah/domain/entities/daily_ayah.dart';

class DailyAyahShareCard extends StatelessWidget {
  const DailyAyahShareCard({
    super.key,
    required this.ayah,
    required this.captureKey,
  });

  final DailyAyah ayah;
  final GlobalKey captureKey;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      key: captureKey,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: dark
                  ? const [Color(0xFF263B33), Color(0xFF17251F)]
                  : const [Color(0xFFF5F8F4), Color(0xFFE5EEE7)],
            ),
            border: Border.all(color: scheme.primary.withValues(alpha: .24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_rounded, color: scheme.primary, size: 28),
              const SizedBox(height: 10),
              Text(
                'آية اليوم',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: scheme.primary.withValues(alpha: .22)),
              const SizedBox(height: 14),
              Text(
                ayah.text,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 27,
                  height: 2,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${ayah.surahName} • ${toArabicIndicDigits(ayah.ayahNumber)}',
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              NotificationLogo(
                color: dark
                    ? const Color(0xFFB8F2D5)
                    : scheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
