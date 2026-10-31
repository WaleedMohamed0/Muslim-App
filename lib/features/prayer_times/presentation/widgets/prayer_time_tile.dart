import 'package:flutter/material.dart';
import 'package:untitled8/core/theme/app_theme.dart';

class PrayerTimeTile extends StatelessWidget {
  const PrayerTimeTile({
    super.key,
    required this.name,
    required this.time,
    required this.period,
    required this.icon,
    this.isNext = false,
  });

  final String name;
  final String time;
  final String period;
  final IconData icon;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isNext ? colors.onPrimaryContainer : colors.onSurface;
    return Card(
      color: isNext ? colors.primaryContainer : colors.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isNext
                    ? colors.primary.withValues(alpha: .12)
                    : colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.tile),
              ),
              child: Icon(icon, color: colors.primary, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    time,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    period,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
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
