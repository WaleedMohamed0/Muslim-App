import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'daily_wird_reader_screen.dart';
import '../../data/repositories/daily_wird_configuration_repository.dart';
import '../../data/repositories/daily_wird_progress_repository.dart';

class DailyWirdSettingsScreen extends StatefulWidget {
  const DailyWirdSettingsScreen({super.key});
  @override
  State<DailyWirdSettingsScreen> createState() => _DailyWirdSettingsScreenState();
}

class _DailyWirdSettingsScreenState extends State<DailyWirdSettingsScreen> {
  final _repository = DailyWirdConfigurationRepository();
  final _progressRepository = DailyWirdProgressRepository();
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  bool _completedToday = false;
  bool _startedToday = false;
  DailyWirdStreakStats? _streak;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      _repository.loadPagesPerDay(),
      _progressRepository.isCompletedToday(),
      _progressRepository.loadStreakStats(),
      _progressRepository.hasStartedToday(),
    ]);
    if (!mounted) return;
    setState(() {
      final pages = results[0] as int?;
      _completedToday = results[1] as bool;
      _streak = results[2] as DailyWirdStreakStats;
      _startedToday = results[3] as bool;
      if (pages != null) _controller.text = toArabicIndicDigits(pages);
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pages = int.parse(_toWesternDigits(_controller.text.trim()));
    setState(() => _saving = true);
    await _repository.savePagesPerDay(pages);
    if (!mounted) return;
    setState(() => _saving = false);
    AppSnackBar.show(message: 'تم حفظ إعداد الورد اليومي بنجاح', success: true);
    Navigator.of(context).pop(true);
  }

  Future<void> _openWird() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/daily-wird-reader'),
        builder: (_) => const DailyWirdReaderScreen(),
      ),
    );
    if (!mounted) return;
    final completed = await _progressRepository.isCompletedToday();
    final started = await _progressRepository.hasStartedToday();
    if (mounted && (completed != _completedToday || started != _startedToday)) {
      setState(() {
        _completedToday = completed;
        _startedToday = started;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final lightBorder = theme.colorScheme.primary.withValues(alpha: 0.45);

    return Scaffold(
    appBar: defaultAppBar(context: context, text: 'إعداد الورد اليومي'),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
              children: [
                _WirdStreakSummary(stats: _streak),
                const SizedBox(height: 16),
                if (_completedToday) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.onTertiaryContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'أتممت وردك اليومي اليوم، تقبّل الله منك.',
                            textDirection: TextDirection.rtl,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _startedToday
                                    ? 'وردك اليومي بانتظارك، أكمل القراءة من حيث وصلت.'
                                    : 'لا تنسَ وردك اليومي، دقائق مع القرآن تملأ يومك بركة.',
                                textDirection: TextDirection.rtl,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _openWird,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(_startedToday ? 'أكمل وردي الآن' : 'ابدأ وردك الآن'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('اختر عدد صفحات وردك اليومي. سيكمل الورد تلقائيًا من موضعه في اليوم التالي.', textDirection: TextDirection.rtl, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 8),
                    child: Text(
                      'عدد الصفحات يوميًا',
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _controller,
                  style: isLightMode
                      ? TextStyle(color: theme.colorScheme.onSurface)
                      : null,
                  cursorColor: isLightMode ? theme.colorScheme.primary : null,
                  textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_ArabicDigitsInputFormatter()],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: isLightMode,
                    fillColor: isLightMode ? theme.colorScheme.surface : null,
                    hintStyle: isLightMode
                        ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
                        : null,
                    enabledBorder: isLightMode
                        ? OutlineInputBorder(
                            borderSide: BorderSide(color: lightBorder),
                          )
                        : null,
                    focusedBorder: isLightMode
                        ? OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          )
                        : null,
                    suffixIcon: const Icon(Icons.menu_book_rounded),
                  ),
                  validator: (text) {
                    final pages = int.tryParse(_toWesternDigits(text ?? ''));
                    if (pages == null || pages < 1 || pages > 604) return 'أدخل عددًا من ١ إلى ٦٠٤ صفحات';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ الإعداد')),
              ],
            ),
          ),
    );
  }
}

class _WirdStreakSummary extends StatelessWidget {
  const _WirdStreakSummary({required this.stats});

  final DailyWirdStreakStats? stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = stats;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.local_fire_department_rounded, color: colors.tertiary),
              const SizedBox(width: 8),
              Text(
                'استمرارك في الورد',
                textDirection: TextDirection.rtl,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _StreakValue(label: 'السلسلة الحالية', value: value?.currentStreak ?? 0),
              _StreakValue(label: 'أفضل سلسلة', value: value?.bestStreak ?? 0),
              _StreakValue(label: 'أيام مكتملة', value: value?.totalCompletedDays ?? 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakValue extends StatelessWidget {
  const _StreakValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            toArabicIndicDigits(value),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _toWesternDigits(String value) => value.replaceAllMapped(
  RegExp(r'[٠-٩۰-۹]'),
  (match) {
    final digit = match[0]!.codeUnitAt(0);
    final zero = digit >= 0x06f0 ? 0x06f0 : 0x0660;
    return String.fromCharCode(0x30 + digit - zero);
  },
);

class _ArabicDigitsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String arabicDigits(String value) => value
        .replaceAllMapped(RegExp(r'[0-9]'), (match) => toArabicIndicDigits(match[0]!))
        .replaceAll(RegExp(r'[^٠-٩۰-۹]'), '');

    final prefixEnd = newValue.selection.extentOffset
        .clamp(0, newValue.text.length)
        .toInt();
    final text = arabicDigits(newValue.text);
    final cursor = arabicDigits(newValue.text.substring(0, prefixEnd)).length;
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }
}
