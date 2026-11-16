import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/khatmah/presentation/cubit/khatmah_cubit.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/app/data/repositories/daily_wird_configuration_repository.dart';
import 'package:muslim/features/app/data/repositories/daily_wird_progress_repository.dart';
import 'package:muslim/features/app/presentation/pages/daily_wird_reader_screen.dart';
import 'package:muslim/features/app/presentation/daily_wird_route_observer.dart';

class DailyWirdHomeCard extends StatefulWidget {
  const DailyWirdHomeCard({super.key});

  @override
  State<DailyWirdHomeCard> createState() => _DailyWirdHomeCardState();
}

class _DailyWirdHomeCardState extends State<DailyWirdHomeCard>
    with WidgetsBindingObserver, RouteAware {
  PageRoute<dynamic>? _subscribedRoute;
  final _configuration = DailyWirdConfigurationRepository();
  final _progress = DailyWirdProgressRepository();
  DailyWirdSession? _session;
  DailyWirdStreakStats? _streak;
  int? _pagesPerDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DailyWirdConfigurationRepository.configurationVersion.addListener(
      _onConfigurationChanged,
    );
    _load();
  }

  void _onConfigurationChanged() {
    _load();
  }

  @override
  void dispose() {
    dailyWirdRouteObserver.unsubscribe(this);
    DailyWirdConfigurationRepository.configurationVersion.removeListener(
      _onConfigurationChanged,
    );
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _subscribedRoute) {
      dailyWirdRouteObserver.unsubscribe(this);
      _subscribedRoute = route;
      dailyWirdRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    final pages = await _configuration.loadPagesPerDay();
    final plan = context.read<KhatmahCubit>().state;
    final session = pages == null ? null : await _progress.prepareSession(pages, checkpointPage: plan?.checkpointPage ?? 1, checkpointSurah: plan?.checkpointSurah ?? 1, checkpointAyah: plan?.checkpointAyah ?? 1);
    final streak = await _progress.loadStreakStats();
    if (!mounted) return;
    setState(() {
      _pagesPerDay = pages;
      _session = session;
      _streak = streak;
    });
  }

  Future<void> _openReader() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/daily-wird'),
        builder: (_) => const DailyWirdReaderScreen(),
      ),
    );
    await _load();
  }

  String _pageCount(int count) => switch (count) {
    0 => 'لا توجد صفحات متبقية',
    1 => 'صفحة واحدة',
    2 => 'صفحتان',
    _ => '${toArabicIndicDigits(count)} صفحات',
  };

  String _pageUnit(int count) => switch (count) {
    1 => 'صفحة',
    2 => 'صفحتان',
    _ => 'صفحات',
  };

  @override
  Widget build(BuildContext context) {
    if (_session?.completed == true) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    final session = _session;
    final total = session == null
        ? (_pagesPerDay ?? 0)
        : session.endPage - session.startPage + 1;
    final completedPages = session == null
        ? 0
        : session.completed
        ? total
        : (session.checkpointPage - session.startPage).clamp(0, total).toInt();
    final fraction = total == 0 ? 0.0 : completedPages / total;
    final percent = (fraction * 100).round();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
        onTap: _openReader,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(Icons.menu_book_rounded,
                        color: colors.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الورد اليومي',
                            textDirection: TextDirection.rtl,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(
                          _pagesPerDay == null
                              ? 'اضبط وردك اليومي وابدأ القراءة'
                              : session?.completed == true
                                  ? 'أتممت وردك اليوم، تقبّل الله منك'
                                  : 'هدف اليوم ${_pageCount(_pagesPerDay ?? total)}',
                          textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _openReader,
                    child: Text(session?.completed == true
                        ? 'مراجعة الورد'
                        : 'متابعة الورد'),
                  ),
                ],
              ),
              if (_pagesPerDay != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تقدم اليوم', style: Theme.of(context).textTheme.labelSmall),
                    Text(
                      '${toArabicIndicDigits(completedPages)} / ${toArabicIndicDigits(total)} ${_pageUnit(total)}',
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: colors.surfaceContainerHighest,
                      color: session?.completed == true ? colors.tertiary : colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${toArabicIndicDigits(percent)}٪',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: session?.completed == true ? colors.tertiary : colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if ((_streak?.currentStreak ?? 0) > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: colors.primaryContainer.withValues(alpha: .45), borderRadius: BorderRadius.circular(14)),
                  child: Row(textDirection: TextDirection.rtl, children: [
                    Icon(Icons.local_fire_department_rounded, size: 20, color: colors.tertiary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('سلسلة وردك: ${toArabicIndicDigits(_streak!.currentStreak)} يوم — داوم على تلاوة القرآن', textDirection: TextDirection.rtl, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    Icon(Icons.radio_button_unchecked_rounded, size: 19, color: colors.onSurfaceVariant),
                  ]),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}
