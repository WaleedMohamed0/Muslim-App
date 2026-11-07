import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/features/aqeedah/data/pillars_content.dart';

Color _categoryAccent(BuildContext context, PillarCategory category) {
  if (Theme.of(context).brightness != Brightness.dark) return category.color;
  return category.title == 'أركان الإسلام'
      ? const Color(0xFF8ED7B5)
      : const Color(0xFFE5C17F);
}

String _arabicDigits(Object value) => value
    .toString()
    .replaceAll('0', '٠')
    .replaceAll('1', '١')
    .replaceAll('2', '٢')
    .replaceAll('3', '٣')
    .replaceAll('4', '٤')
    .replaceAll('5', '٥')
    .replaceAll('6', '٦')
    .replaceAll('7', '٧')
    .replaceAll('8', '٨')
    .replaceAll('9', '٩');

class PillarsScreen extends StatefulWidget {
  const PillarsScreen({super.key});
  @override
  State<PillarsScreen> createState() => _PillarsScreenState();
}

class _PillarsScreenState extends State<PillarsScreen> {
  static const _visitedKey = 'aqeedah_pillars_visited_v1';
  static const _completedKey = 'aqeedah_pillars_completed_v1';
  Set<String> visited = {}, completed = {};

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      visited = (prefs.getStringList(_visitedKey) ?? []).toSet();
      completed = (prefs.getStringList(_completedKey) ?? []).toSet();
    });
  }
  Future<void> _open(PillarLesson lesson) async {
    final prefs = await SharedPreferences.getInstance();
    visited.add(lesson.id);
    await prefs.setStringList(_visitedKey, visited.toList());
    if (mounted) setState(() {});
    if (!mounted) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PillarDetailScreen(
      lesson: lesson, isCompleted: completed.contains(lesson.id), onCompleted: (value) async {
        if (value) { completed.add(lesson.id); } else { completed.remove(lesson.id); }
        await prefs.setStringList(_completedKey, completed.toList());
        if (mounted) setState(() {});
      },
    )));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('أركان الإسلام والإيمان', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 28), children: [
      Text('رحلة قصيرة لتتعرف على أصول دينك. اقرأ كل درس، ثم علّمه كمكتمل لتتابع تقدمك.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
      const SizedBox(height: 18),
      for (final category in [islamPillars, imanPillars]) ...[
        _CategoryHeader(category: category, count: completed.intersection(category.lessons.map((e) => e.id).toSet()).length),
        const SizedBox(height: 10),
        for (var i = 0; i < category.lessons.length; i++)
          _PillarCard(lesson: category.lessons[i], index: i + 1, color: _categoryAccent(context, category), visited: visited.contains(category.lessons[i].id), completed: completed.contains(category.lessons[i].id), onTap: () => _open(category.lessons[i])),
        const SizedBox(height: 22),
      ],
    ]),
  ));
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category, required this.count});
  final PillarCategory category; final int count;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = count / category.lessons.length;
    final isDark = theme.brightness == Brightness.dark;
    // The original category hues are intentionally subdued for light mode;
    // use brighter variants in dark mode so headings and progress stay clear.
    final accent = _categoryAccent(context, category);
    return Card(color: accent.withValues(alpha: isDark ? .13 : .09), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(category.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: accent))), Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 10, 5),
        decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? .18 : .12), borderRadius: BorderRadius.circular(999)),
        child: Text('${_arabicDigits(count)} / ${_arabicDigits(category.lessons.length)}', style: theme.textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: accent)),
      )]),
      const SizedBox(height: 4), Text(category.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 8, color: accent, backgroundColor: accent.withValues(alpha: isDark ? .2 : .15))),
      const SizedBox(height: 5), Text('${_arabicDigits((progress * 100).round())}٪ مكتمل', style: theme.textTheme.labelSmall?.copyWith(fontSize: 13, color: accent, fontWeight: FontWeight.w700)),
    ])));
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.lesson, required this.index, required this.color, required this.visited, required this.completed, required this.onTap});
  final PillarLesson lesson; final int index; final Color color; final bool visited, completed; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(margin: const EdgeInsets.only(bottom: 9), clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(lesson.icon, color: color)), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(lesson.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(completed ? 'مكتمل' : 'الدرس ${_arabicDigits(index)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))])),
      Icon(completed ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded, size: completed ? 20 : 15, color: completed ? color : theme.colorScheme.onSurfaceVariant),
    ]))));
  }
}

class PillarDetailScreen extends StatefulWidget {
  const PillarDetailScreen({super.key, required this.lesson, required this.isCompleted, required this.onCompleted});
  final PillarLesson lesson; final bool isCompleted; final ValueChanged<bool> onCompleted;
  @override
  State<PillarDetailScreen> createState() => _PillarDetailScreenState();
}

class _PillarDetailScreenState extends State<PillarDetailScreen> {
  late bool completed = widget.isCompleted;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final c = theme.colorScheme;
    Widget section(String title, Widget content, IconData icon) => Card(margin: const EdgeInsets.only(top: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 19, color: c.primary), const SizedBox(width: 8), Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))]), const SizedBox(height: 10), content])));
    Widget paragraph(String text) => Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.8));
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: Text(widget.lesson.title)), body: ListView(padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 28), children: [
      Card(color: c.primaryContainer, child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [CircleAvatar(radius: 24, backgroundColor: c.surface.withValues(alpha: .7), child: Icon(widget.lesson.icon, color: c.primary, size: 24)), const SizedBox(width: 14), Expanded(child: Text(widget.lesson.title, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: c.onPrimaryContainer)))]))),
      section('شرح مبسط', paragraph(widget.lesson.explanation), Icons.lightbulb_outline_rounded),
      section('أهميته ومكانته', paragraph(widget.lesson.importance), Icons.stars_rounded),
      section('من القرآن الكريم', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('﴿${widget.lesson.verse}﴾', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(height: 2, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(widget.lesson.reference, style: theme.textTheme.labelMedium?.copyWith(color: c.primary, fontWeight: FontWeight.bold))]), Icons.menu_book_rounded),
      if (widget.lesson.hadith != null) section('من السنة النبوية', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [paragraph('«${widget.lesson.hadith}»'), const SizedBox(height: 8), Text(widget.lesson.hadithSource!, style: theme.textTheme.labelMedium?.copyWith(color: c.primary, fontWeight: FontWeight.bold))]), Icons.format_quote_rounded),
      section('في حياتنا اليومية', paragraph(widget.lesson.example), Icons.volunteer_activism_outlined),
      const SizedBox(height: 18),
      _CompletionAction(
        completed: completed,
        onComplete: () {
          if (completed) return;
          setState(() => completed = true);
          widget.onCompleted(true);
        },
      ),
    ])));
  }
}

class _CompletionAction extends StatelessWidget {
  const _CompletionAction({required this.completed, required this.onComplete});

  final bool completed;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final success = isDark ? const Color(0xFF8ED7B5) : const Color(0xFF36765D);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: completed
              ? OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.check_circle_rounded, color: success),
                  label: Text(
                    'تم إكمال هذا الركن',
                    style: TextStyle(color: success, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: success.withValues(alpha: isDark ? .12 : .08),
                    side: BorderSide(color: success.withValues(alpha: .35)),
                  ),
                )
              : FilledButton(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('أنهيت تعلّم هذا الركن'),
                ),
        ),
        const SizedBox(height: 9),
        Text(
          'خطوة جديدة في رحلتك لتعلّم دينك 🌙',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
