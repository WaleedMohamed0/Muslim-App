import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/khatmah/presentation/cubit/khatmah_cubit.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/app/data/repositories/daily_wird_configuration_repository.dart';
import 'package:muslim/features/app/data/repositories/daily_wird_progress_repository.dart';
import 'package:muslim/features/app/presentation/pages/daily_wird_reader_screen.dart';

class DailyWirdHomeCard extends StatefulWidget {
  const DailyWirdHomeCard({super.key});

  @override
  State<DailyWirdHomeCard> createState() => _DailyWirdHomeCardState();
}

class _DailyWirdHomeCardState extends State<DailyWirdHomeCard> {
  final _configuration = DailyWirdConfigurationRepository();
  final _progress = DailyWirdProgressRepository();
  DailyWirdSession? _session;
  int? _pagesPerDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pages = await _configuration.loadPagesPerDay();
    final plan = context.read<KhatmahCubit>().state;
    final session = pages == null ? null : await _progress.prepareSession(pages, checkpointPage: plan?.checkpointPage ?? 1, checkpointSurah: plan?.checkpointSurah ?? 1, checkpointAyah: plan?.checkpointAyah ?? 1);
    if (!mounted) return;
    setState(() {
      _pagesPerDay = pages;
      _session = session;
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
    final current = session == null
        ? 0
        : session.completed
            ? total
            : (session.checkpointPage - session.startPage).clamp(0, total);
    final remaining = (total - current).clamp(0, total);
    final fraction = total == 0 ? 0.0 : current / total;

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
                                  : 'المتبقي ${_pageCount(remaining)}',
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
                    Text('${toArabicIndicDigits(current)} / ${toArabicIndicDigits(total)} ${_pageUnit(total)}',
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: colors.surfaceContainerHighest,
                    color: session?.completed == true ? colors.tertiary : colors.primary,
                  ),
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
