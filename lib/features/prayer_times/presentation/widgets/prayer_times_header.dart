import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/prayer_times/presentation/models/prayer_schedule_item.dart';

class PrayerTimesIntroCard extends StatelessWidget {
  const PrayerTimesIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            colors.primaryContainer,
            Color.lerp(colors.primaryContainer, colors.primary, .24)!,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -46,
            end: -34,
            child: IgnorePointer(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: .10),
                    width: 12,
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '﴿إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا﴾',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 1,
                    color: colors.primary.withValues(alpha: .35),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Text(
                      '[النساء: 103]',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 1,
                    color: colors.primary.withValues(alpha: .35),
                  ),
                ],
              ),
            ],
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.prayer.display.period,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.onPrimary.withValues(alpha: .82),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.prayer.display.time,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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
