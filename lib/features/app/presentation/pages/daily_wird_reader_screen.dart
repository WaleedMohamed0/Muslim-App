import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/app/data/repositories/daily_wird_configuration_repository.dart';
import 'package:muslim/features/app/data/repositories/daily_wird_progress_repository.dart';
import 'package:muslim/features/quran/presentation/pages/surah_screen.dart';
import 'daily_wird_settings_screen.dart';

class DailyWirdReaderScreen extends StatefulWidget {
  const DailyWirdReaderScreen({super.key});
  @override
  State<DailyWirdReaderScreen> createState() => _DailyWirdReaderScreenState();
}

class _DailyWirdReaderScreenState extends State<DailyWirdReaderScreen> {
  final _configuration = DailyWirdConfigurationRepository();
  final _progress = DailyWirdProgressRepository();
  DailyWirdSession? _session;
  int? _currentPage;
  bool _loading = true;
  bool _initialPageReported = false;
  bool _completionPresented = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pages = await _configuration.loadPagesPerDay();
    final session =
        pages == null ? null : await _progress.prepareSession(pages);
    if (!mounted) return;
    setState(() {
      _session = session;
      _loading = false;
    });
  }

  Future<void> _configure() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(name: '/daily-wird-settings'),
        builder: (_) => const DailyWirdSettingsScreen(),
      ),
    );
    if (saved == true) {
      setState(() => _loading = true);
      await _load();
    }
  }

  void _recordPage(int page, int surah, int ayah) {
    final session = _session;
    if (session == null || page < session.startPage || page > session.endPage)
      return;
    unawaited(_progress.savePosition(page, surah, ayah));
    if (mounted) setState(() => _currentPage = page);
    if (!_initialPageReported) {
      _initialPageReported = true;
      return;
    }
    if (page == session.endPage && !session.completed) _finish();
  }

  void _finish() {
    if (_completionPresented || !mounted) return;
    _completionPresented = true;
    final session = _session;
    if (session != null)
      setState(
        () =>
            _session = DailyWirdSession(
              startPage: session.startPage,
              endPage: session.endPage,
              checkpointPage: session.checkpointPage,
              checkpointSurah: session.checkpointSurah,
              checkpointAyah: session.checkpointAyah,
              completed: true,
            ),
      );
    // Present the completion state before waiting on storage, which can take
    // noticeably longer on first access to SharedPreferences.
    unawaited(_progress.completeToday());
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder:
            (dialogContext) => _DailyWirdCompletionDialog(
              onReturnHome: () {
                Navigator.of(dialogContext).pop();
                if (mounted) Navigator.of(context).pop();
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final session = _session;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الورد اليومي')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اضبط عدد الصفحات التي تريد قراءتها يوميًا.',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _configure,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('إعداد الورد اليومي'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final page = session.checkpointPage;
    final savedSurah = session.checkpointSurah;
    final data = MushafLineLayoutData.pageData(page);
    final hasSurah = data.any(
      (item) => (item['surah'] as num).toInt() == savedSurah,
    );
    final surah = hasSurah ? savedSurah : (data.first['surah'] as num).toInt();
    final ayah =
        hasSurah
            ? session.checkpointAyah
            : (data.firstWhere(
                      (item) => (item['surah'] as num).toInt() == surah,
                    )['start']
                    as num)
                .toInt();
    final current = _currentPage ?? page;
    final percent =
        (((current - session.startPage + 1) /
                    (session.endPage - session.startPage + 1)) *
                100)
            .round();
    final progress = (percent / 100).clamp(0.0, 1.0).toDouble();
    return Stack(
      children: [
        SurahScreen(
          key: ValueKey(
            'daily-wird-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
          ),
          surahNumber: surah,
          initialAyah: ayah,
          initialPageNumber: page,
          saveGeneralCheckpoint: false,
          onPageRead: _recordPage,
          minimumPageNumber: session.startPage,
          maximumPageNumber: session.endPage,
        ),
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + 54,
          start: 16,
          end: 16,
          child: IgnorePointer(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _DailyWirdProgress(
                completed: current - session.startPage + 1,
                total: session.endPage - session.startPage + 1,
                percent: percent,
                progress: progress,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyWirdProgress extends StatelessWidget {
  const _DailyWirdProgress({
    required this.completed,
    required this.total,
    required this.percent,
    required this.progress,
  });
  final int completed;
  final int total;
  final int percent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ورد اليوم',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Text(
                '${toArabicIndicDigits(completed)} / ${toArabicIndicDigits(total)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder:
                  (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    backgroundColor: colors.surfaceContainerHighest,
                    color: colors.primary,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${toArabicIndicDigits(percent)}٪',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyWirdCompletionDialog extends StatelessWidget {
  const _DailyWirdCompletionDialog({required this.onReturnHome});
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .75, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder:
                (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 36,
                color: colors.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'أتممت وردك اليومي',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'تقبّل الله منك، وجعل القرآن نورًا لك.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton.icon(
          onPressed: onReturnHome,
          icon: const Icon(Icons.home_rounded),
          label: const Text('العودة للرئيسية'),
        ),
      ],
    );
  }
}
