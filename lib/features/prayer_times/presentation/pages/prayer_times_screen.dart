import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:untitled8/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:untitled8/features/prayer_times/presentation/widgets/prayer_times_content.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<PrayerTimesCubit>();
    if (cubit.state.status == PrayerTimesStatus.initial && cubit.isOnline) {
      cubit.getPrayerTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: defaultAppBar(
            context: context,
            text: 'مواقيت الصلاة',
            actions: [
              IconButton(
                tooltip: 'تحديث المواقيت',
                onPressed: () {
                  final cubit = context.read<PrayerTimesCubit>();
                  if (cubit.isOnline) {
                    cubit.getPrayerTime();
                  } else {
                    AppSnackBar.show(message: 'يلزم الاتصال بالإنترنت لتحديث المواقيت');
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: switch (state.status) {
            PrayerTimesStatus.initial || PrayerTimesStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            PrayerTimesStatus.failure => _PrayerTimesError(
              message: state.error ?? 'تعذر تحميل مواقيت الصلاة',
              onRetry: () => context.read<PrayerTimesCubit>().getPrayerTime(),
            ),
            PrayerTimesStatus.loaded => PrayerTimesContent(state: state),
          },
        );
      },
    );
  }
}

class _PrayerTimesError extends StatelessWidget {
  const _PrayerTimesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}
