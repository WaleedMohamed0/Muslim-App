import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_widgets.dart';

import '../cubit/qibla_cubit.dart';
import '../cubit/qibla_state.dart';
import '../widgets/qibla_compass_dial.dart';

class QiblaCompassScreen extends StatelessWidget {
  const QiblaCompassScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => QiblaCubit()..initialize(),
    child: const _QiblaCompassView(),
  );
}

class _QiblaCompassView extends StatefulWidget {
  const _QiblaCompassView();

  @override
  State<_QiblaCompassView> createState() => _QiblaCompassViewState();
}

class _QiblaCompassViewState extends State<_QiblaCompassView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final qiblaState = context.read<QiblaCubit>().state;
      if (qiblaState.status != QiblaStatus.ready) {
        context.read<QiblaCubit>().initialize();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: defaultAppBar(context: context, text: 'بوصلة القبلة'),
    body: SafeArea(
      child: BlocBuilder<QiblaCubit, QiblaState>(
        builder: (context, state) {
          if (state.status == QiblaStatus.loading ||
              state.status == QiblaStatus.initial) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('جارٍ تحديد اتجاه القبلة…'),
                ],
              ),
            );
          }
          if (state.status != QiblaStatus.ready) {
            return _LocationHelp(state: state);
          }
          return _CompassContent(state: state);
        },
      ),
    ),
  );
}

class _CompassContent extends StatelessWidget {
  const _CompassContent({required this.state});

  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bearing = state.qiblaBearing!;
    final heading = state.heading;
    final rotation =
        heading == null ? null : QiblaCubit.rotationToQibla(bearing, heading);
    final width = MediaQuery.sizeOf(context).width;
    final compassSize = math.min(width - 64, 330.0).clamp(230.0, 330.0);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 22, 28),
          children: [
            Text(
              'حرّك هاتفك حتى يشير المؤشر إلى اتجاه القبلة',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            if (state.compassAvailable == true && heading != null)
              Center(
                child: QiblaCompassDial(
                  heading: heading,
                  qiblaBearing: bearing,
                ),
              )
            else
              _CompassUnavailable(
                size: compassSize,
                bearing: bearing,
                waiting: state.compassAvailable == null,
              ),
            const SizedBox(height: 22),
            if (state.compassAvailable == true && heading != null)
              _DirectionStatus(rotation: rotation!, colors: colors),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DirectionValueCard(
                    label: 'اتجاه القبلة',
                    value: '${toArabicIndicDigits(bearing.round() % 360)}°',
                    icon: Icons.mosque_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DirectionValueCard(
                    label: 'اتجاه الهاتف',
                    value:
                        heading == null
                            ? '—'
                            : '${toArabicIndicDigits(heading.round() % 360)}°',
                    icon: Icons.explore_rounded,
                  ),
                ),
              ],
            ),
            if (state.compassAvailable == true &&
                (state.accuracy == null || state.accuracy! > 30)) ...[
              const SizedBox(height: 14),
              const _CalibrationHint(),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompassUnavailable extends StatelessWidget {
  const _CompassUnavailable({
    required this.size,
    required this.bearing,
    required this.waiting,
  });

  final double size;
  final double bearing;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surfaceContainerHigh,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              waiting ? Icons.explore_rounded : Icons.explore_off_rounded,
              size: 48,
              color: colors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              waiting
                  ? 'جارٍ الاتصال بالبوصلة…'
                  : 'لا تتوفر بوصلة في هذا الجهاز',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'اتجاه القبلة ${toArabicIndicDigits(bearing.round() % 360)}°',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionStatus extends StatelessWidget {
  const _DirectionStatus({required this.rotation, required this.colors});

  final double rotation;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final isAligned = rotation.abs() < 4;
    final direction = rotation > 0 ? 'يمينًا' : 'يسارًا';
    final text =
        isAligned
            ? 'أنت باتجاه القبلة'
            : 'استدر $direction بمقدار ${toArabicIndicDigits(rotation.abs().round())}°';
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 13, 16, 13),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAligned
                ? Icons.check_circle_rounded
                : Icons.screen_rotation_alt_rounded,
            color: colors.primary,
            size: 20,
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionValueCard extends StatelessWidget {
  const _DirectionValueCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 13, 12, 13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .65)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(height: 7),
          Text(
            label,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationHint extends StatelessWidget {
  const _CalibrationHint();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'قد تكون قراءة البوصلة غير دقيقة. حرّك الهاتف على شكل رقم ٨ لمعايرتها.',
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onTertiaryContainer,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationHelp extends StatelessWidget {
  const _LocationHelp({required this.state});

  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDenied = state.status == QiblaStatus.permissionDenied;
    final isPermanentlyDenied =
        state.status == QiblaStatus.permissionPermanentlyDenied;
    final isServiceDisabled =
        state.status == QiblaStatus.locationServicesDisabled;
    final title =
        isDenied || isPermanentlyDenied
            ? 'يلزم إذن الموقع لحساب اتجاه القبلة'
            : isServiceDisabled
            ? 'خدمات الموقع غير مفعّلة'
            : state.error ?? 'تعذر تحديد اتجاه القبلة';
    final description =
        isDenied || isPermanentlyDenied
            ? 'يُستخدم موقعك الحالي لحساب الاتجاه إلى الكعبة، ولا يُحفظ أو يُرسل عبر الإنترنت.'
            : isServiceDisabled
            ? 'فعّل خدمات الموقع على جهازك ثم أعد المحاولة.'
            : 'تحقق من إعدادات الموقع ثم حاول مرة أخرى.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDenied || isPermanentlyDenied
                      ? Icons.location_on_outlined
                      : Icons.explore_off_rounded,
                  color: colors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _handleAction(context, state),
                icon: Icon(
                  isDenied
                      ? Icons.location_on_rounded
                      : isPermanentlyDenied
                      ? Icons.settings_rounded
                      : isServiceDisabled
                      ? Icons.location_searching_rounded
                      : Icons.refresh_rounded,
                ),
                label: Text(
                  isDenied
                      ? 'السماح بالوصول للموقع'
                      : isPermanentlyDenied
                      ? 'فتح إعدادات التطبيق'
                      : isServiceDisabled
                      ? 'تفعيل خدمات الموقع'
                      : 'إعادة المحاولة',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, QiblaState state) async {
    if (state.status == QiblaStatus.permissionDenied) {
      final accepted = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('إذن الموقع', textDirection: TextDirection.rtl),
              content: const Text(
                'نحتاج إلى موقعك الحالي لحساب اتجاه القبلة بدقة. يُستخدم الموقع على جهازك فقط.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('ليس الآن'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('متابعة'),
                ),
              ],
            ),
      );
      if (accepted == true && context.mounted) {
        await context.read<QiblaCubit>().requestLocationPermission();
      }
      return;
    }
    if (state.status == QiblaStatus.permissionPermanentlyDenied) {
      await Geolocator.openAppSettings();
      return;
    }
    if (state.status == QiblaStatus.locationServicesDisabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    await context.read<QiblaCubit>().initialize();
  }
}
