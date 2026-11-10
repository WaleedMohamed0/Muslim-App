import 'package:flutter/material.dart';
import 'package:muslim/features/prayer_times/domain/entities/prayer_times.dart'
    as prayer_model;
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:muslim/features/prayer_times/domain/entities/next_prayer.dart'
    as prayer_logic;
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:muslim/features/prayer_times/presentation/models/prayer_schedule_item.dart';
import 'package:muslim/features/prayer_times/presentation/widgets/prayer_time_tile.dart';
import 'package:muslim/features/prayer_times/presentation/widgets/prayer_times_header.dart';

class PrayerTimesContent extends StatelessWidget {
  const PrayerTimesContent({super.key, required this.state});

  final PrayerTimesState state;

  @override
  Widget build(BuildContext context) {
    final prayers = _buildPrayers(state.prayerTimes, state.displayTimes);
    final now = DateTime.now();
    final upcoming = prayer_logic.nextPrayerAfter(
      state.prayerTimes,
      now,
      triggeredOccurrences: PrayerAdhanService.instance.triggeredOccurrences,
    );
    final nextPrayerIndex = upcoming == null
        ? null
        : const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']
            .indexOf(upcoming.id);
    final nextPrayerTime = upcoming?.at;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 28),
          children: [
            const PrayerTimesIntroCard(),
            const SizedBox(height: 18),
            if (nextPrayerIndex != null && nextPrayerTime != null) ...[
              PrayerTimesNextCard(
                prayer: prayers[nextPrayerIndex],
                nextAt: nextPrayerTime,
              ),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                Text(
                  'مواقيت اليوم',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'الصَّلَاة نور يومك',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < prayers.length; index++) ...[
              PrayerTimeTile(
                name: prayers[index].display.name,
                time: prayers[index].display.time,
                period: prayers[index].display.period,
                icon: prayers[index].icon,
                isNext: index == nextPrayerIndex,
              ),
              if (index != prayers.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  List<PrayerScheduleItem> _buildPrayers(
    prayer_model.PrayerTimes? times,
    List<PrayerDisplayTime> displayTimes,
  ) {
    if (times == null || displayTimes.length < 5) return const [];
    final timesOfDay = [
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];
    const icons = [
      Icons.wb_twilight_rounded,
      Icons.wb_sunny_rounded,
      Icons.access_time_filled_rounded,
      Icons.wb_twilight_outlined,
      Icons.nights_stay_rounded,
    ];
    return List.generate(
      5,
      (index) => PrayerScheduleItem(
        display: displayTimes[index],
        time: timesOfDay[index],
        icon: icons[index],
      ),
    );
  }

}

