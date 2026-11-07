import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_back_arrow.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:muslim/features/prayer_times/domain/entities/prayer_times.dart';
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';

class PrayerExperienceCard extends StatefulWidget {
  const PrayerExperienceCard({
    super.key,
    this.onTap,
    this.onPlayingTap,
    this.onDarkBackground = false,
  });

  final VoidCallback? onTap;
  final ValueChanged<String>? onPlayingTap;
  final bool onDarkBackground;

  @override
  State<PrayerExperienceCard> createState() => _PrayerExperienceCardState();
}

class _PrayerExperienceCardState extends State<PrayerExperienceCard>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Timer? _playbackPoller;
  bool _isPlaying = false;
  bool _checkingPlayback = false;
  String? _playingPrayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(context.read<PrayerTimesCubit>().loadCachedPrayerTimes());
    _startUpdates();
    unawaited(_refreshPlaybackState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _playbackPoller?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startUpdates();
      unawaited(_refreshPlaybackState());
    } else {
      _ticker?.cancel();
      _playbackPoller?.cancel();
    }
  }

  void _startUpdates() {
    _ticker?.cancel();
    _playbackPoller?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _playbackPoller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_refreshPlaybackState()),
    );
  }

  Future<void> _refreshPlaybackState() async {
    if (_checkingPlayback) return;
    _checkingPlayback = true;
    try {
      final state = await PrayerAdhanService.instance.getPlaybackState();
      if (!mounted) return;
      final isPlaying = state['playing'] == true;
      final prayer = isPlaying ? state['prayer'] as String? : null;
      if (_isPlaying != isPlaying || _playingPrayer != prayer) {
        setState(() {
          _isPlaying = isPlaying;
          _playingPrayer = prayer;
        });
      }
    } catch (_) {
      if (mounted && (_isPlaying || _playingPrayer != null)) {
        setState(() {
          _isPlaying = false;
          _playingPrayer = null;
        });
      }
    } finally {
      _checkingPlayback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtitleStyle = theme.textTheme.bodySmall;
    final times = context.watch<PrayerTimesCubit>().state.prayerTimes;
    final next = _nextPrayer(times, DateTime.now());
    final playingName = _prayerName(_playingPrayer);
    final isPlaying = _isPlaying && playingName != null;
    final title =
        isPlaying
            ? 'حان الآن وقت صلاة $playingName'
            : next == null
            ? 'مواقيت الصلاة'
            : 'الصلاة القادمة: ${next.name}';
    final subtitle =
        isPlaying
            ? 'الأذان يعمل الآن'
            : next == null
            ? 'اضغط لعرض مواقيت الصلاة'
            : 'متبقي ${_formatRemaining(next.at.difference(DateTime.now()))}';
    final foregroundColor =
        widget.onDarkBackground
            ? Colors.white
            : isPlaying
            ? colors.onPrimaryContainer
            : colors.onSecondaryContainer;
    final surfaceColor =
        widget.onDarkBackground
            ? Colors.white.withValues(alpha: .13)
            : isPlaying
            ? colors.primaryContainer
            : colors.secondaryContainer;
    final onTap =
        isPlaying && _playingPrayer != null && widget.onPlayingTap != null
            ? () => widget.onPlayingTap!(_playingPrayer!)
            : widget.onTap;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isPlaying
                      ? Icons.notifications_active_rounded
                      : Icons.mosque_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        title,
                        key: ValueKey(title),
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: foregroundColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      style: subtitleStyle?.copyWith(
                        fontSize: 15,
                        color: foregroundColor.withValues(alpha: .78),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      isPlaying
                          ? Container(
                            key: const ValueKey('adhan_notification'),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colors.surface.withValues(alpha: .72),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(child: AppBackArrow()),
                          )
                          : AppBackArrow(key: const ValueKey('next_prayer')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _NextPrayer? _nextPrayer(PrayerTimes? times, DateTime now) {
    if (times == null) return null;
    const prayers = <(String, String)>[
      ('الفجر', 'fajr'),
      ('الظهر', 'dhuhr'),
      ('العصر', 'asr'),
      ('المغرب', 'maghrib'),
      ('العشاء', 'isha'),
    ];
    final prayerTimes = [
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];
    for (var index = 0; index < prayerTimes.length; index++) {
      final time = prayerTimes[index];
      final today = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (today.isAfter(now)) return _NextPrayer(prayers[index].$1, today);
    }
    final fajr = prayerTimes.first;
    return _NextPrayer(
      prayers.first.$1,
      DateTime(now.year, now.month, now.day + 1, fajr.hour, fajr.minute),
    );
  }

  String? _prayerName(String? prayer) => switch (prayer) {
    'fajr' => 'الفجر',
    'dhuhr' => 'الظهر',
    'asr' => 'العصر',
    'maghrib' => 'المغرب',
    'isha' => 'العشاء',
    _ => null,
  };

  String _formatRemaining(Duration remaining) {
    final totalSeconds = remaining.inSeconds.clamp(0, 864000);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final value =
        hours > 0
            ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
            : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return toArabicIndicDigits(value);
  }
}

class _NextPrayer {
  const _NextPrayer(this.name, this.at);

  final String name;
  final DateTime at;
}
