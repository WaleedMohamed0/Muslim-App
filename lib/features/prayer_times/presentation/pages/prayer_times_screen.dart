import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:muslim/features/prayer_times/presentation/widgets/prayer_times_content.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final cubit = context.read<PrayerTimesCubit>();
    cubit.getPrayerTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState != AppLifecycleState.resumed || !mounted) return;
    final cubit = context.read<PrayerTimesCubit>();
    final errorType = cubit.state.errorType;
    if (errorType == PrayerTimesErrorType.locationServicesDisabled ||
        errorType == PrayerTimesErrorType.locationPermissionDenied ||
        errorType == PrayerTimesErrorType.locationPermissionPermanentlyDenied) {
      cubit.getPrayerTime(forceRefresh: true);
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
                    cubit.getPrayerTime(forceRefresh: true);
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
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text(
                      'جارٍ تحميل مواقيت الصلاة...',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            PrayerTimesStatus.failure => _PrayerTimesError(
              message: state.error ?? 'تعذر تحميل مواقيت الصلاة',
              errorType: state.errorType,
              onRetry: () => context.read<PrayerTimesCubit>().getPrayerTime(),
              onOpenLocationSettings: Geolocator.openLocationSettings,
              onOpenAppSettings: Geolocator.openAppSettings,
            ),
            PrayerTimesStatus.loaded => PrayerTimesContent(state: state),
          },
        );
      },
    );
  }
}

class _PrayerTimesError extends StatelessWidget {
  const _PrayerTimesError({
    required this.message,
    required this.onRetry,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
    this.errorType,
  });

  final String message;
  final PrayerTimesErrorType? errorType;
  final VoidCallback onRetry;
  final Future<bool> Function() onOpenLocationSettings;
  final Future<bool> Function() onOpenAppSettings;

  @override
  Widget build(BuildContext context) {
    final isLocationError = switch (errorType) {
      PrayerTimesErrorType.locationServicesDisabled ||
      PrayerTimesErrorType.locationPermissionDenied ||
      PrayerTimesErrorType.locationPermissionPermanentlyDenied ||
      PrayerTimesErrorType.locationUnavailable => true,
      _ => false,
    };
    late final String actionLabel;
    late final IconData actionIcon;
    late final VoidCallback actionCallback;
    switch (errorType) {
      case PrayerTimesErrorType.locationServicesDisabled:
        actionLabel = 'فتح إعدادات الموقع';
        actionIcon = Icons.location_on_outlined;
        actionCallback = () => onOpenLocationSettings();
        break;
      case PrayerTimesErrorType.locationPermissionPermanentlyDenied:
        actionLabel = 'فتح إعدادات التطبيق';
        actionIcon = Icons.settings_outlined;
        actionCallback = () => onOpenAppSettings();
        break;
      case PrayerTimesErrorType.locationPermissionDenied:
        actionLabel = 'فتح إعدادات التطبيق';
        actionIcon = Icons.settings_outlined;
        actionCallback = () => onOpenAppSettings();
        break;
      default:
        actionLabel = 'إعادة المحاولة';
        actionIcon = Icons.refresh_rounded;
        actionCallback = onRetry;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocationError ? Icons.location_off_outlined : Icons.cloud_off_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: actionCallback,
              icon: Icon(actionIcon),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
