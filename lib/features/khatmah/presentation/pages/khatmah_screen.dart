import 'package:flutter/material.dart';
import 'package:muslim/core/widgets/app_time_picker.dart';
import 'package:muslim/core/widgets/app_switch.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_back_arrow.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../core/utils/arabic_digits.dart';
import '../../../quran/presentation/pages/surah_screen.dart';
import '../../domain/khatmah_plan.dart';
import '../cubit/khatmah_cubit.dart';

class KhatmahScreen extends StatelessWidget {
  const KhatmahScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<KhatmahCubit, KhatmahPlan?>(
    builder:
        (context, plan) => Scaffold(
          appBar: AppBar(title: const Text('خطة الختمة')),
          body: plan == null ? const _CreatePlan() : _Dashboard(plan: plan),
        ),
  );
}

class _CreatePlan extends StatefulWidget {
  const _CreatePlan();

  @override
  State<_CreatePlan> createState() => _CreatePlanState();
}

class _CreatePlanState extends State<_CreatePlan> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final options = [7, 15, 30, 40];
    final pages = (604 / _days).ceil();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'اختر مدّة الختمة',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'قسّم قراءتك اليومية بخطة تناسب وقتك.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ...options.map(
                  (d) => ChoiceChip(
                    label: Text(
                      '${toArabicIndicDigits(d)} يوم${d == 30 ? ' · موصى بها' : ''}',
                    ),
                    selected: _days == d,
                    onSelected:
                        (_) => setState(() {
                          _days = d;
                        }),
                  ),
                ),
                ChoiceChip(
                  label: const Text('مخصص'),
                  selected: !options.contains(_days),
                  onSelected: (_) async {
                    final value = await showDialog<int>(
                      context: context,
                      builder: (_) => _CustomDaysDialog(initialDays: _days),
                    );
                    if (value != null && mounted) {
                      setState(() {
                        _days = value.clamp(1, 604);
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'حوالي ${toArabicIndicDigits(pages)} صفحة يوميًا',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.read<KhatmahCubit>().create(_days),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('إنشاء الْخُطَّة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomDaysDialog extends StatefulWidget {
  const _CustomDaysDialog({required this.initialDays});

  final int initialDays;

  @override
  State<_CustomDaysDialog> createState() => _CustomDaysDialogState();
}

class _CustomDaysDialogState extends State<_CustomDaysDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: toArabicIndicDigits(widget.initialDays),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('مدّة مخصصة'),
    content: TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'عدد الأيام'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: () {
          final n = int.tryParse(
            _controller.text.replaceAllMapped(
              RegExp('[٠-٩]'),
              (m) => String.fromCharCode(
                m[0]!.codeUnitAt(0) - 0x0660 + 0x0030,
              ),
            ),
          );
          Navigator.pop(context, n != null && n > 0 ? n : null);
        },
        child: const Text('اختيار'),
      ),
    ],
  );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.plan});

  final KhatmahPlan plan;

  String _name(int surah) {
    final name = quran.getSurahNameArabic(surah);
    return name == 'اللهب' ? 'المسد' : name;
  }

  String _dayOrdinal(int day) {
    const ordinals = [
      'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع',
      'الثامن', 'التاسع', 'العاشر', 'الحادي عشر', 'الثاني عشر',
      'الثالث عشر', 'الرابع عشر', 'الخامس عشر', 'السادس عشر',
      'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
      'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون',
      'الرابع والعشرون', 'الخامس والعشرون', 'السادس والعشرون',
      'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
      'الحادي والثلاثون', 'الثاني والثلاثون', 'الثالث والثلاثون',
      'الرابع والثلاثون', 'الخامس والثلاثون', 'السادس والثلاثون',
      'السابع والثلاثون', 'الثامن والثلاثون', 'التاسع والثلاثون', 'الأربعون',
    ];
    return day > 0 && day <= ordinals.length
        ? ordinals[day - 1]
        : toArabicIndicDigits(day);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<KhatmahCubit>();
    final today = plan.schedule[plan.currentDay - 1];
    final colors = Theme.of(context).colorScheme;
    final completedDays = plan.schedule.where(plan.isDayComplete).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('رحلتك مع القرآن', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(20)),
                      child: Text('${toArabicIndicDigits((plan.progress * 100).round())}٪', style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: plan.progress, minHeight: 10),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('${toArabicIndicDigits(plan.pagesRead)} من ٦٠٤ صفحة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                    Text('باقي ${toArabicIndicDigits(plan.remainingPages)} صفحة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 5),
                Text('أتممت ${toArabicIndicDigits(completedDays)} من ${toArabicIndicDigits(plan.durationDays)} يومًا', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: colors.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_twilight_rounded, color: colors.primary),
                    const SizedBox(width: 9),
                    Expanded(child: Text('ورد اليوم', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onPrimaryContainer))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'اليوم ${_dayOrdinal(today.day)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الصفحات', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 3),
                      Text('${toArabicIndicDigits(today.startPage)} – ${toArabicIndicDigits(today.endPage)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
                      const SizedBox(height: 8),
                      Text('من ${_name(today.startSurah)}، آية ${toArabicIndicDigits(today.startAyah)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurface)),
                      Text('إلى ${_name(today.endSurah)}، آية ${toArabicIndicDigits(today.endAyah)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurface)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('${toArabicIndicDigits(today.pages)} صفحة في ورد اليوم', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('آخر موضع قراءة', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('${_name(plan.checkpointSurah)} · الجزء ${toArabicIndicDigits(plan.checkpointJuz)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('صفحة ${toArabicIndicDigits(plan.checkpointPage)} · آية ${toArabicIndicDigits(plan.checkpointAyah)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: plan.paused ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SurahScreen(surahNumber: plan.checkpointSurah, initialAyah: plan.checkpointAyah, initialPageNumber: plan.checkpointPage, trackKhatmahProgress: true))),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(plan.checkpointPage > 1 || plan.checkpointAyah > 1 ? 'أكمل القراءة' : 'ابدأ القراءة'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSwitchListTile(
                leading: Icon(Icons.notifications_active_outlined, color: colors.primary),
                title: const Text('التذكير اليومي'),
                subtitle: Text(
                  toArabicIndicDigits(
                    MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay(
                        hour: plan.reminderHour,
                        minute: plan.reminderMinute,
                      ),
                      alwaysUse24HourFormat: false,
                    ),
                  ),
                ),
                value: plan.reminderEnabled,
                onChanged: (value) => cubit.setReminder(
                  enabled: value,
                  hour: plan.reminderHour,
                  minute: plan.reminderMinute,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(bottom: 20),
                    minimumSize: const Size(64, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () async {
                    final time = await AppTimePicker.show(
                      context: context,
                      initialTime: TimeOfDay(hour: plan.reminderHour, minute: plan.reminderMinute),
                    );
                    if (time == null || !context.mounted) return;
                    await cubit.setReminder(
                      enabled: plan.reminderEnabled,
                      hour: time.hour,
                      minute: time.minute,
                    );
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('تغيير الوقت'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'جدول الختمة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('اضغط على أي يوم لبدء القراءة من موضعه.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...plan.schedule.map((day) {
          final done = plan.isDayComplete(day);
          final isToday = day.day == plan.currentDay;
          final pagesRead =
              List.generate(
                day.pages,
                (i) => day.startPage + i,
              ).where(plan.completedPages.contains).length;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: isToday ? colors.primaryContainer.withValues(alpha: 0.42) : colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isToday
                    ? colors.primary.withValues(alpha: 0.45)
                    : colors.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SurahScreen(surahNumber: day.startSurah, initialAyah: day.startAyah))),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 15, 12, 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: done ? colors.primaryContainer : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : Icons.menu_book_outlined,
                        color: done ? colors.primary : colors.onSurfaceVariant,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'اليوم ${_dayOrdinal(day.day)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                              if (isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'ورد اليوم',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (done)
                                Text(
                                  'مكتمل',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.menu_book_rounded, size: 16, color: colors.primary),
                              Text(
                                'الصفحات ${toArabicIndicDigits(day.startPage)}–${toArabicIndicDigits(day.endPage)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${toArabicIndicDigits(pagesRead)} من ${toArabicIndicDigits(day.pages)}',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'من سورة ${_name(day.startSurah)}، آية ${toArabicIndicDigits(day.startAyah)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            'إلى سورة ${_name(day.endSurah)}، آية ${toArabicIndicDigits(day.endAyah)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: AppBackArrow(size: 15, color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (plan.pagesRead == 604)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: FilledButton.icon(
              onPressed:
                  () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const KhatmahScreen(),
                    ),
                  ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إنشاء ختمة جديدة'),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => cubit.setPaused(!plan.paused),
              icon: Icon(plan.paused ? Icons.play_arrow : Icons.pause),
              label: Text(plan.paused ? 'استئناف' : 'إيقاف مؤقت'),
            ),
            OutlinedButton.icon(
              onPressed:
                  () => _confirm(context, 'إعادة بدء الخطة؟', cubit.restart),
              icon: const Icon(Icons.restart_alt),
              label: const Text('إعادة البدء'),
            ),
            TextButton(
              onPressed:
                  () => _confirm(
                    context,
                    'إلغاء الْخُطَّة وحذف التقدم؟',
                    cubit.cancel,
                  ),
              child: const Text('إلغاء الْخُطَّة'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    Future<void> Function() action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: const Text('سيُطلب منك التأكيد قبل تغيير خطتك.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('رجوع'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
    );
    if (ok == true) await action();
  }
}
