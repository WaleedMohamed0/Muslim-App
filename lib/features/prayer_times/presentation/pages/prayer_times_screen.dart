import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/theme/app_theme.dart';

import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:untitled8/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:untitled8/features/prayer_times/presentation/pages/elazan_screen.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/prayer_times/presentation/widgets/prayer_time_tile.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});
  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  bool _adhanHandled = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PrayerTimesCubit>();
    if (cubit.state.status == PrayerTimesStatus.initial && cubit.isOnline)
      cubit.getPrayerTime();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrayerTimesCubit, PrayerTimesState>(
      listener: (context, state) {
        if (state.isAzanTime && !_adhanHandled) {
          _adhanHandled = true;
          context.read<QuranCubit>().playAzan();
          navigateTo(context, ElAzanScreen(prayer: state.azanPrayer!));
        }
      },
      builder: (context, state) {
        if (state.status == PrayerTimesStatus.loading ||
            state.status == PrayerTimesStatus.initial) {
          return Scaffold(
            appBar: defaultAppBar(context: context, text: 'مواقيت الصلاة'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == PrayerTimesStatus.failure) {
          return Scaffold(
            appBar: defaultAppBar(context: context, text: 'مواقيت الصلاة'),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.error ?? 'تعذر تحميل مواقيت الصلاة',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: defaultAppBar(context: context, text: 'مواقيت الصلاة'),
          body: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.dialog),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_twilight_rounded,
                      size: 34,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'الصلاة نور يومك\nحافظ على مواقيتها',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (
                var index = 0;
                index < state.displayTimes.length;
                index++
              ) ...[
                PrayerTimeTile(
                  name: state.displayTimes[index].name,
                  time: state.displayTimes[index].time,
                  period: state.displayTimes[index].period,
                ),
                if (index != state.displayTimes.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}
