import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/assets/app_assets.dart';
import 'package:untitled8/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:untitled8/features/prayer_times/presentation/widgets/prayer_experience_card.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';

class ElAzanScreen extends StatelessWidget {
  const ElAzanScreen({super.key, required this.prayer});

  final String prayer;

  Future<void> _close(BuildContext context) async {
    try {
      await context.read<QuranCubit>().stopAzan();
    } catch (_) {}
    try {
      await PrayerAdhanService.instance.stopAudio();
    } catch (_) {}
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // The Isha photo is a night scene; keep its overlay dark in light mode too
    // so the image does not get washed out by the light surface gradient.
    final isDark =
        theme.brightness == Brightness.dark || prayer.trim() == 'العشاء';
    const azanNight = Color(0xFF10231F);
    final foreground = isDark ? Colors.white : colors.onSurface;
    final mutedForeground =
        isDark ? Colors.white.withValues(alpha: .84) : colors.onSurfaceVariant;
    final subtitleForeground =
        isDark ? Colors.white.withValues(alpha: .78) : colors.onSurfaceVariant;
    final surfaceOverlay =
        isDark ? Colors.white.withValues(alpha: .12) : colors.surface.withValues(alpha: .84);
    final borderOverlay =
        isDark ? Colors.white.withValues(alpha: .22) : colors.outlineVariant;
    final badgeBorder =
        isDark ? Colors.white.withValues(alpha: .16) : colors.outlineVariant;
    return Scaffold(
      backgroundColor: isDark ? azanNight : theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.adhanBackgroundForPrayer(prayer),
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    isDark
                        ? [
                          azanNight.withValues(alpha: .46),
                          azanNight.withValues(alpha: .48),
                          azanNight.withValues(alpha: .94),
                        ]
                        :[],
                stops: const [0, .42, 1],
              ),
            ),
          ),
          PositionedDirectional(
            top: -86,
            end: -72,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: .10)
                        : colors.secondary.withValues(alpha: .25),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'إغلاق وإيقاف الأذان',
                              onPressed: () => _close(context),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    isDark
                                        ? Colors.white.withValues(alpha: .14)
                                        : colors.surface,
                                foregroundColor: foreground,
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                12,
                                8,
                                12,
                                8,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceOverlay,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: badgeBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mosque_rounded,
                                    color: foreground,
                                    size: 18,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'تنبيه الصلاة',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      color: foreground,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        Container(
                          width: 82,
                          height: 82,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: surfaceOverlay,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: borderOverlay,
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: foreground,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'حان الآن وقت صلاة',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          prayer,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'حيّ على الصلاة',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: subtitleForeground,
                            letterSpacing: .2,
                          ),
                        ),
                        const Spacer(),
                        PrayerExperienceCard(onDarkBackground: isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
