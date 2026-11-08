import 'package:flutter/material.dart';
import 'package:muslim/core/widgets/app_time_picker.dart';
import 'package:muslim/core/widgets/app_switch.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';

class DailyReminderSettingsScreen extends StatefulWidget {
  const DailyReminderSettingsScreen({super.key});

  @override
  State<DailyReminderSettingsScreen> createState() =>
      _DailyReminderSettingsScreenState();
}

class _DailyReminderSettingsScreenState extends State<DailyReminderSettingsScreen>
    with WidgetsBindingObserver {
  final _service = PrayerAdhanService.instance;
  List<Map<String, dynamic>> _reminders = const [];
  bool _loading = true;
  bool _saving = false;
  Map<String, bool> _permissions = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getDailyReminders(),
        _service.permissionStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _reminders = List<Map<String, dynamic>>.from(results[0] as List);
        _permissions = results[1] as Map<String, bool>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackBar.show(message: 'تعذر تحميل تذكيراتك اليومية');
      }
    }
  }

  Future<bool> _explain(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title, textDirection: TextDirection.rtl),
          content: Text(
            message,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.start,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
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
      ) ??
      false;

  Future<bool> _ensureNotificationPermission() async {
    if (_permissions['notifications'] == true) return true;
    final accepted = await _explain(
      'السماح بالإشعارات',
      'نحتاج إلى الإشعارات لنعرض تذكيرات الأذكار والورد في الأوقات التي تختارها.',
    );
    if (!accepted) return false;
    await _service.requestNotificationPermission();
    _permissions = await _service.permissionStatus();
    if (_permissions['notifications'] != true && mounted) {
      AppSnackBar.show(
        message: 'فعّل الإشعارات من إعدادات الجهاز لتشغيل التذكيرات.',
      );
      return false;
    }
    return true;
  }

  Future<void> _maybeRequestExactAlarmAccess() async {
    if (_permissions['exactAlarms'] == true) return;
    final accepted = await _explain(
      'السماح بالتنبيه في الوقت المحدد',
      'يساعد إذن المنبهات الدقيقة على وصول التذكير في وقته. إذا لم تسمح به، سيستخدم التطبيق جدولة بديلة وقد يتأخر التنبيه.',
    );
    if (accepted) await _service.requestExactAlarmPermission();
  }

  Future<void> _setReminder(int index, bool enabled) async {
    if (_saving) return;
    if (enabled && !await _ensureNotificationPermission()) return;
    if (enabled) await _maybeRequestExactAlarmAccess();
    final updated = _copyReminders();
    updated[index]['enabled'] = enabled;
    await _save(updated);
  }

  Future<void> _setTime(int index) async {
    if (_saving) return;
    final reminder = _reminders[index];
    final initial = TimeOfDay(
      hour: reminder['hour'] as int,
      minute: reminder['minute'] as int,
    );
    final time = await AppTimePicker.show(
      context: context,
      initialTime: initial,
    );
    if (time == null || !mounted) return;
    final updated = _copyReminders();
    updated[index]['hour'] = time.hour;
    updated[index]['minute'] = time.minute;
    await _save(updated);
  }

  List<Map<String, dynamic>> _copyReminders() => _reminders
      .map((reminder) => Map<String, dynamic>.from(reminder))
      .toList(growable: true);

  List<MapEntry<int, Map<String, dynamic>>> get _visibleReminders => [
    for (var index = 0; index < _reminders.length; index++)
      if (_reminders[index]['route'] != 'salawat')
        MapEntry(index, _reminders[index]),
  ];

  Future<void> _save(List<Map<String, dynamic>> reminders) async {
    setState(() => _saving = true);
    try {
      final saved = await _service.saveDailyReminders(reminders);
      if (mounted) setState(() => _reminders = saved);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(message: 'تعذر حفظ إعدادات التذكير');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatTime(BuildContext context, Map<String, dynamic> reminder) {
    final time = TimeOfDay(
      hour: reminder['hour'] as int,
      minute: reminder['minute'] as int,
    ).format(context);
    final arabicTime = time.replaceAllMapped(
      RegExp(r'[0-9]'),
      (match) => String.fromCharCode(
        0x0660 + int.parse(match.group(0)!),
      ),
    );
    final scheduled = reminder['scheduled'] == true;
    final enabled = reminder['enabled'] == true;
    final status = scheduled
        ? 'مجدول'
        : enabled
        ? 'بانتظار الجدولة'
        : 'متوقف';
    return '$arabicTime · $status';
  }

  IconData _iconFor(String id) => switch (id) {
    'morning' => Icons.wb_twilight_rounded,
    'evening' => Icons.nights_stay_rounded,
    _ => Icons.menu_book_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: defaultAppBar(context: context, text: 'التذكيرات اليومية'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Text(
                    'اختر التذكيرات التي تناسبك وحدد وقت كل منها. تعمل التذكيرات محليًا دون اتصال بالإنترنت.',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < _visibleReminders.length; index++) ...[
                  _reminderCard(
                    context,
                    _visibleReminders[index].value,
                    _visibleReminders[index].key,
                  ),
                  if (index != _visibleReminders.length - 1)
                    const SizedBox(height: 12),
                ],
                if (_saving) ...[
                  const SizedBox(height: 12),
                  const Center(child: LinearProgressIndicator()),
                ],
              ],
            ),
    );
  }

  Widget _reminderCard(
    BuildContext context,
    Map<String, dynamic> reminder,
    int index,
  ) {
    final colors = Theme.of(context).colorScheme;
    final scheduled = reminder['scheduled'] == true;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 12, 8),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconFor(reminder['id'] as String), color: colors.primary),
              title: Text(
                reminder['title'] as String,
                textDirection: TextDirection.rtl,
              ),
              subtitle: Text(
                _formatTime(context, reminder),
                textDirection: TextDirection.rtl,
              ),
              trailing: AppSwitch(
                value: scheduled,
                onChanged: _saving ? null : (value) => _setReminder(index, value),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: _saving ? null : () => _setTime(index),
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('تغيير الوقت'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
