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

class _PrayerTimesState extends State<PrayerTimes> {
  Future<void> _showRefreshFailure(PrayerTimesCubit cubit) async {
    switch (cubit.lastRefreshErrorType) {
      case PrayerTimesErrorType.locationServicesDisabled:
        await _showLocationSettingsPrompt(
          title: 'خدمات الموقع متوقفة',
          message: 'فعّل خدمات الموقع على جهازك لإحضار موقعك الحالي. سنواصل استخدام موقعك السابق حتى ذلك الحين.',
          openSettings: Geolocator.openLocationSettings,
          actionLabel: 'إعدادات الموقع',
        );
        return;
      case PrayerTimesErrorType.locationPermissionPermanentlyDenied:
        await _showLocationSettingsPrompt(
          title: 'إذن الموقع مرفوض نهائيًا',
          message: 'اسمح للتطبيق بالوصول إلى الموقع من إعدادات التطبيق. سنواصل استخدام موقعك السابق حتى تغيّر الإذن.',
          openSettings: Geolocator.openAppSettings,
          actionLabel: 'إعدادات التطبيق',
        );
        return;
      case PrayerTimesErrorType.locationPermissionDenied:
        AppSnackBar.show(
          message: 'لم يتم السماح بإذن الموقع. اضغط تحديث الموقع للمحاولة مرة أخرى؛ سنواصل استخدام موقعك السابق.',
        );
        return;
      case PrayerTimesErrorType.locationUnavailable:
        AppSnackBar.show(
          message: 'تعذر تحديد الموقع الحالي؛ سنواصل استخدام موقعك السابق ومواقيته.',
        );
        return;
      case PrayerTimesErrorType.network:
        AppSnackBar.show(
          message: 'تعذر تحديث المواقيت دون اتصال بالإنترنت؛ ما زلنا نستخدم مواقيتك المحفوظة.',
        );
        return;
      default:
        AppSnackBar.show(
          message: 'تعذر تحديث الموقع؛ ما زلنا نستخدم موقعك السابق ومواقيته.',
        );
    }
  }

  Future<void> _showLocationSettingsPrompt({
    required String title,
    required String message,
    required Future<bool> Function() openSettings,
    required String actionLabel,
  }) async {
    if (!mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, textDirection: TextDirection.rtl),
        content: Text(message, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('لاحقًا'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (open == true) await openSettings();
  }

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PrayerTimesCubit>();
    cubit.getPrayerTime();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: defaultAppBar(
            context: context,
            text: 'مواقيت الصَّلَاة',
            actions: [
              IconButton(
                tooltip: 'تحديث المواقيت',
                onPressed: () async {
                  final cubit = context.read<PrayerTimesCubit>();
                  final succeeded = await cubit.getPrayerTime(forceRefresh: true);
                  if (!context.mounted) return;
                  if (succeeded) {
                    AppSnackBar.show(
                      message: 'تم تحديث الموقع ومواقيت الصَّلَاة',
                      success: true,
                    );
                  } else {
                    await _showRefreshFailure(cubit);
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
                      'جارٍ تحميل مواقيت الصَّلَاة...',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            PrayerTimesStatus.failure => _PrayerTimesError(
              message: state.error ?? 'تعذر تحميل مواقيت الصَّلَاة',
              errorType: state.errorType,
              onRetry: () => context.read<PrayerTimesCubit>().getPrayerTime(forceRefresh: true),
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
        actionLabel = 'إعادة المحاولة';
        actionIcon = Icons.refresh_rounded;
        actionCallback = onRetry;
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
