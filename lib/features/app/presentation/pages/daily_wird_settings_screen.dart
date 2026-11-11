import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
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

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      _repository.loadPagesPerDay(),
      _progressRepository.isCompletedToday(),
    ]);
    if (!mounted) return;
    setState(() {
      final pages = results[0] as int?;
      _completedToday = results[1] as bool;
      if (pages != null) _controller.text = '$pages';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pages = int.parse(_controller.text.trim());
    setState(() => _saving = true);
    await _repository.savePagesPerDay(pages);
    if (!mounted) return;
    setState(() => _saving = false);
    AppSnackBar.show(message: 'تم حفظ إعداد الورد اليومي بنجاح', success: true);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: defaultAppBar(context: context, text: 'إعداد الورد اليومي'),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
              children: [
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
                ],
                Text('اختر عدد صفحات وردك اليومي. سيكمل الورد تلقائيًا من موضعه في اليوم التالي.', textDirection: TextDirection.rtl, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'صفحة يوميًا', border: OutlineInputBorder(), suffixIcon: Icon(Icons.menu_book_rounded)),
                  validator: (text) {
                    final pages = int.tryParse(text ?? '');
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
