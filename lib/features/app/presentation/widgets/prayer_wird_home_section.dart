import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/widgets/app_back_arrow.dart';
import 'package:muslim/features/app/data/repositories/prayer_wird_progress_repository.dart';
import 'package:muslim/features/app/domain/entities/prayer_wird_period.dart';
import 'package:muslim/features/prayer_times/domain/entities/prayer_times.dart';
import 'package:muslim/features/prayer_times/domain/use_cases/get_prayer_times.dart';
import 'package:muslim/features/prayer_times/data/data_sources/prayer_location_data_source.dart';
import 'package:muslim/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:muslim/features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'package:muslim/features/azkar/presentation/cubit/azkar_cubit.dart';

class PrayerWirdHomeSection extends StatefulWidget {
  const PrayerWirdHomeSection({super.key});

  @override
  State<PrayerWirdHomeSection> createState() => _PrayerWirdHomeSectionState();
}

class _PrayerWirdHomeSectionState extends State<PrayerWirdHomeSection>
    with WidgetsBindingObserver {
  final _progress = PrayerWirdProgressRepository();
  final _getPrayerTimes = GetPrayerTimes(
    PrayerTimesRepositoryImpl(PrayerLocationDataSource()),
  );
  Timer? _ticker;
  PrayerTimes? _cachedTimes;
  String? _period;
  Set<String> _completed = <String>{};
  bool _loading = true;
  bool _postAzanEligible = false;
  static const _cards = <(String, String, IconData)>[
    ('azkar', 'أذكار بعد الصلاة', Icons.volunteer_activism_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final postAzanEligible = await _progress.isPostAzanEligible();
    final now = DateTime.now();
    final current = context.read<PrayerTimesCubit>().state.prayerTimes;
    PrayerTimes? times = current;
    if (times == null ||
        times.fajr.year != now.year ||
        times.fajr.month != now.month ||
        times.fajr.day != now.day) {
      final previouslyLoaded = times;
      try {
        times = await _getPrayerTimes.getCached(now);
      } catch (_) {
        times = null;
      }
      // The local prayer cache is intentionally daily. If it has not yet been
      // refreshed for this date, retain the loaded schedule's local clock
      // times so period tracking still rolls over offline.
      times ??=
          previouslyLoaded == null ? null : _onDate(previouslyLoaded, now);
    }
    if (!mounted) return;
    final nextPeriod = prayerWirdPeriodKey(times, now);
    if (nextPeriod == null) {
      setState(() {
        _postAzanEligible = postAzanEligible;
        _cachedTimes = null;
        _period = null;
        _loading = false;
      });
      return;
    }
    final completed = await _progress.completedFor(nextPeriod);
    if (!mounted) return;
    setState(() {
      _postAzanEligible = postAzanEligible;
      _cachedTimes = times;
      _period = nextPeriod;
      _completed = completed;
      _loading = false;
    });
  }

  PrayerTimes _onDate(PrayerTimes times, DateTime date) {
    DateTime rebase(DateTime time) => DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      time.second,
    );
    return PrayerTimes(
      fajr: rebase(times.fajr),
      dhuhr: rebase(times.dhuhr),
      asr: rebase(times.asr),
      maghrib: rebase(times.maghrib),
      isha: rebase(times.isha),
      alarmTimes: times.alarmTimes,
    );
  }

  Future<void> _complete(String id) async {
    final now = DateTime.now();
    final period = prayerWirdPeriodKey(_cachedTimes, now);
    if (period == null) return;
    final completed =
        period == _period ? _completed : await _progress.completedFor(period);
    await _progress.markCompleted(period, id);
    if (!mounted) return;
    setState(() {
      _period = period;
      _completed = {...completed, id};
    });
  }

  Future<void> _open() async {
    final now = DateTime.now();
    final period = prayerWirdPeriodKey(_cachedTimes, now);
    if (period == null) return;
    await context.read<AzkarCubit>().beginPostPrayerSession(period);
    if (!mounted) return;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(name: '/azkar-category-4'),
        builder: (_) => const AzkarAndHadeethScreen(index: 4),
      ),
    );
    if (completed == true) await _complete('azkar');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrayerTimesCubit, PrayerTimesState>(
      listener: (_, __) => _refresh(),
      child: Builder(
        builder: (context) {
          if (_loading ||
              !_postAzanEligible ||
              _cachedTimes == null ||
              _period == null ||
              _cards.every((card) => _completed.contains(card.$1))) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final visible =
              _cards.where((card) => !_completed.contains(card.$1)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(
                          alpha:
                              theme.brightness == Brightness.dark ? .18 : .10,
                        ),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [
                          colors.primaryContainer.withValues(alpha: .72),
                          colors.surface,
                        ],
                      ),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: .12),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _PrayerWirdCard(
                            card: visible[i],
                            onOpen: _open,
                            onComplete:
                                () => unawaited(_complete(visible[i].$1)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrayerWirdCard extends StatelessWidget {
  const _PrayerWirdCard({
    required this.card,
    required this.onOpen,
    required this.onComplete,
  });

  final (String, String, IconData) card;
  final VoidCallback onOpen;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(card.$3, color: colors.onPrimaryContainer, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.$2,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'اضغط للقراءة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppBackArrow(),
            ],
          ),
        ),
      ),
    );
  }
}
