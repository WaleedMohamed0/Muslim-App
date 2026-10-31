import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/core/utils/arabic_digits.dart';
import 'package:untitled8/features/prayer_times/presentation/models/prayer_schedule_item.dart';

class PrayerTimesIntroCard extends StatelessWidget {
  const PrayerTimesIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
            child: Icon(Icons.mosque_outlined, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصلاة نور يومك',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'حافظ على صلاتك في وقتها',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrayerTimesNextCard extends StatefulWidget {
  const PrayerTimesNextCard({
    super.key,
    required this.prayer,
    required this.nextAt,
  });

  final PrayerScheduleItem prayer;
  final DateTime nextAt;

  @override
  State<PrayerTimesNextCard> createState() => _PrayerTimesNextCardState();
}

class _PrayerTimesNextCardState extends State<PrayerTimesNextCard> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remaining = widget.nextAt.difference(_now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final countdown = hours > 0
        ? '${toArabicIndicDigits(hours)} س  ${toArabicIndicDigits(minutes)} د'
        : '${toArabicIndicDigits(minutes)} د  ${toArabicIndicDigits(seconds)} ث';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.primary, colors.primary.withValues(alpha: .82)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.dialog),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -26,
            end: -16,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 122,
              color: colors.onPrimary.withValues(alpha: .07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'الصلاة القادمة',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onPrimary.withValues(alpha: .82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      widget.prayer.icon,
                      size: 32,
                      color: colors.onPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.prayer.display.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${widget.prayer.display.time} ${widget.prayer.display.period}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: colors.onPrimary.withValues(alpha: .24), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 18,
                      color: colors.onPrimary.withValues(alpha: .88),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'متبقي على الأذان',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimary.withValues(alpha: .88),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      countdown,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
