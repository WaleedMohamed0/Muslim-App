import 'package:flutter/material.dart';
import '../../data/repositories/travel_prayer_progress_repository.dart';
import '../../data/travel_prayer_content.dart';

String _arabicDigits(Object value) => value.toString().replaceAllMapped(
  RegExp(r'[0-9]'),
  (match) => String.fromCharCode(match[0]!.codeUnitAt(0) + 0x0660 - 0x0030),
);

class TravelPrayerGuideScreen extends StatefulWidget {
  const TravelPrayerGuideScreen({super.key});

  @override
  State<TravelPrayerGuideScreen> createState() => _TravelPrayerGuideScreenState();
}

class _TravelPrayerGuideScreenState extends State<TravelPrayerGuideScreen> {
  final _repository = TravelPrayerProgressRepository();
  Set<String> _completed = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final completed = await _repository.loadCompleted();
    if (mounted) setState(() { _completed = completed; _loaded = true; });
  }

  Future<void> _mark(String id) async {
    final updated = {..._completed, id};
    setState(() => _completed = updated);
    await _repository.saveCompleted(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('وضع الْمُسَافِر')),
        body: !_loaded ? const Center(child: CircularProgressIndicator()) : CustomScrollView(
          slivers: [
            SliverPadding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), sliver: SliverList.list(children: [
              _HeroCard(completed: _completed.length),
              const SizedBox(height: 18),
              Text('دليل مختصر للصلاة في السَّفَر', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('تعرّف إلى الرخصة، ثم طبّقها على مواقف السَّفَر اليومية.', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 14),
              _LessonCard(title: 'أولاً: قصر الصَّلَاة', id: 'qasar', completed: _completed.contains('qasar'), onComplete: _mark, child: const _QasarContent()),
              _LessonCard(title: 'ثانياً: جمع الصَّلَاة', id: 'jam', completed: _completed.contains('jam'), onComplete: _mark, child: const _JamContent()),
              _LessonCard(title: 'ثالثاً: جدول صَلَاة الْمُسَافِر', id: 'table', completed: _completed.contains('table'), onComplete: _mark, child: const _PrayerTable()),
              _LessonCard(title: 'رابعاً: أحكام مهمة للمسافر', id: 'rules', completed: _completed.contains('rules'), onComplete: _mark, child: const _RulesContent()),
              _LessonCard(title: 'مواقف تطبيقية', id: 'scenarios', completed: _completed.contains('scenarios'), onComplete: _mark, child: const _ScenarioContent()),
              _QuizEntryCard(unlocked: TravelPrayerContent.lessons.every((lesson) => _completed.contains(lesson.id))),
              const SizedBox(height: 12),
              const _SourcesCard(),
              const SizedBox(height: 8),
              Text('هذا دليل تعليمي عام، وقد تختلف تفاصيل السَّفَر ومدته باختلاف الْمَذْهَب والظروف. اسأل عالمًا موثوقًا في الحالات الخاصة.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.6)),
            ])),
          ],
        ),
      ),
    );
  }
}

class _QuizEntryCard extends StatelessWidget {
  const _QuizEntryCard({required this.unlocked});
  final bool unlocked;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: CircleAvatar(child: Icon(unlocked ? Icons.quiz_rounded : Icons.lock_rounded)),
      title: const Text('اختبر فهمك', style: TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(unlocked ? 'أكملت الدروس الخمسة — ابدأ الاختبار' : 'أكمل الدروس الخمسة لفتح الاختبار'),
      trailing: Icon(unlocked ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded, size: 18),
      enabled: unlocked,
      onTap: unlocked ? () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const TravelPrayerQuizScreen())) : null,
    ),
  );
}

class TravelPrayerQuizScreen extends StatefulWidget {
  const TravelPrayerQuizScreen({super.key});
  @override
  State<TravelPrayerQuizScreen> createState() => _TravelPrayerQuizScreenState();
}

class _TravelPrayerQuizScreenState extends State<TravelPrayerQuizScreen> {
  final _repository = TravelPrayerProgressRepository();
  List<int> _answers = [];
  bool _loaded = false;
  bool _unlocked = false;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final completed = await _repository.loadCompleted();
    final answers = await _repository.loadAnswers();
    if (!mounted) return;
    setState(() {
      _unlocked = TravelPrayerContent.lessons.every((lesson) => completed.contains(lesson.id));
      _quizCompleted = completed.contains('quiz');
      _answers = answers;
      _loaded = true;
    });
  }

  Future<void> _answer(int index, int value) async {
    final updated = [..._answers];
    while (updated.length <= index) { updated.add(-1); }
    updated[index] = value;
    setState(() => _answers = updated);
    await _repository.saveAnswers(updated);
  }

  Future<void> _complete() async {
    final completed = await _repository.loadCompleted();
    await _repository.saveCompleted({...completed, 'quiz'});
    if (mounted) setState(() => _quizCompleted = true);
  }

  Future<void> _retake() async {
    final completed = await _repository.loadCompleted();
    completed.remove('quiz');
    await _repository.saveCompleted(completed);
    await _repository.saveAnswers([]);
    if (mounted) setState(() { _quizCompleted = false; _answers = []; });
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('اختبر فهمك')),
      body: !_loaded ? const Center(child: CircularProgressIndicator()) : !_unlocked
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('أكمل الدروس الخمسة أولاً لفتح الاختبار.')))
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text('أجب عن الأسئلة، وستُحفظ إجاباتك تلقائيًا.', style: TextStyle(height: 1.5)),
              const SizedBox(height: 12),
              _QuizContent(answers: _answers, onAnswer: _answer, onComplete: _complete, completed: _quizCompleted, onRetake: _retake),
            ]),
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.completed});
  final int completed;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(color: cs.primaryContainer, child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
      CircleAvatar(radius: 30, backgroundColor: cs.surface.withValues(alpha: .7), child: Icon(Icons.flight_takeoff_rounded, size: 30, color: cs.primary)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('رخصةٌ ورحمة في الطريق', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)), const SizedBox(height: 5), Text('أتممت ${_arabicDigits(completed)} من ${_arabicDigits(TravelPrayerContent.lessons.length)} دروس', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer))])),
    ])));
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.title, required this.id, required this.completed, required this.onComplete, required this.child});
  final String title, id;
  final bool completed;
  final Future<void> Function(String) onComplete;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), clipBehavior: Clip.antiAlias, child: ExpansionTile(
    leading: CircleAvatar(radius: 17, child: completed ? const Icon(Icons.check_rounded, size: 18) : Text(_arabicDigits(TravelPrayerContent.lessons.indexWhere((e) => e.id == id) + 1))),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
    children: [child, const SizedBox(height: 10), Align(alignment: AlignmentDirectional.centerStart, child: TextButton.icon(onPressed: completed ? null : () => onComplete(id), icon: Icon(completed ? Icons.check_circle : Icons.check_circle_outline), label: Text(completed ? 'تم إكمال الدرس' : 'أنهيت هذا الدرس')))],
  ));
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.title, required this.body});
  final String title, body;
  @override
  Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; return Container(margin: const EdgeInsets.only(top: 9), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cs.secondaryContainer.withValues(alpha: .55), borderRadius: BorderRadius.circular(14)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline_rounded, size: 20, color: cs.primary), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55))]))])); }
}

class _QasarContent extends StatelessWidget {
  const _QasarContent();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
    Text('القصر هو أداء الصَّلَاة الرباعية ركعتين في السفر، وهو رخصة ثابتة بالقرآن والسنة؛ قال تعالى: ﴿وَإِذَا ضَرَبْتُمْ فِي الْأَرْضِ فَلَيْسَ عَلَيْكُمْ جُنَاحٌ أَنْ تَقْصُرُوا مِنَ الصَّلَاةِ﴾ [النساء: ١٠١].'),
    _InfoBox(title: 'ما الذي يُقصر؟', body: 'الظُّهْر: ركعتان بدل أربع • الْعَصْر: ركعتان بدل أربع • الْعِشَاء: ركعتان بدل أربع. أما الْمَغْرِب فثلاث والفجر ركعتان كما هما؛ لا قصر فيهما.'),
    _InfoBox(title: 'متى يُعدّ الشخص مسافرًا؟', body: 'يذكر كثير من الْفُقَهَاء مسافة تقارب ٨٠ كم حدًا للسفر، لكن تقدير المسافة ليس محل اتفاق؛ ويرى علماء آخرون أن العبرة بما يعدّه الناس سفرًا عرفًا. لا يبدأ حكم السَّفَر بمجرد النية، بل بعد مفارقة عمران البلد عند جمهور الْفُقَهَاء.'),
    _InfoBox(title: 'مدة الإقامة', body: 'من الأقوال المشهورة: من نوى إقامة أكثر من أربعة أيام يتم الصلاة، ومن نوى أربعة أيام فأقل يقصر؛ وتفاصيل احتساب الأيام والمدة تختلف بين المذاهب، وللعلماء أقوال أخرى. اتبع مذهبك أو اسأل عالمًا موثوقًا.'),
  ]);
}

class _JamContent extends StatelessWidget {
  const _JamContent();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
    Text('الجمع هو أداء صلاتين في وقت إحداهما، ويكون بين الظُّهْر والعصر، أو بين الْمَغْرِب والعشاء. لا تُجمع صَلَاة الْفَجْر مع أي صَلَاة.'),
    _InfoBox(title: 'جمع تقديم', body: 'تصلّي الْعَصْر مع الظُّهْر في وقت الظهر، أو الْعِشَاء مع الْمَغْرِب في وقت الْمَغْرِب. مثال: مسافر يتوقف وقت الظُّهْر فيصلي الظُّهْر ثم الْعَصْر قبل متابعة الطريق.'),
    _InfoBox(title: 'جمع تأخير', body: 'تؤخر الظُّهْر إلى وقت الْعَصْر فتصليهما معًا، أو تؤخر الْمَغْرِب إلى وقت الْعِشَاء. مثال: رحلة لا يتيسر فيها التوقف قبل الغروب، فينزل الْمُسَافِر في وقت الْعِشَاء ويصلي الْمَغْرِب ثم الْعِشَاء.'),
    _InfoBox(title: 'ليس كل سفر يحتاج إلى جمع', body: 'الأفضل غالبًا أن يصلي الْمُسَافِر كل صَلَاة في وقتها إذا لم توجد مشقة؛ والجمع رخصة عند الحاجة. ترتيب الصلاتين والموالاة بينهما لهما تفصيل فقهي.'),
  ]);
}

class _PrayerTable extends StatelessWidget {
  const _PrayerTable();
  @override
  Widget build(BuildContext context) => Table(border: TableBorder.all(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(12)), children: const [
    TableRow(children: [_Cell('الصَّلَاة', bold: true), _Cell('عدد الركعات', bold: true)]),
    TableRow(children: [_Cell('الْفَجْر'), _Cell('٢')]), TableRow(children: [_Cell('الظُّهْر'), _Cell('٢')]),
    TableRow(children: [_Cell('الْعَصْر'), _Cell('٢')]), TableRow(children: [_Cell('الْمَغْرِب'), _Cell('٣')]), TableRow(children: [_Cell('الْعِشَاء'), _Cell('٢')]),
  ]);
}
class _Cell extends StatelessWidget { const _Cell(this.text, {this.bold = false}); final String text; final bool bold; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(11), child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.normal))); }

class _RulesContent extends StatelessWidget {
  const _RulesContent();
  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _InfoBox(title: 'الصَّلَاة خلف إمام مقيم', body: 'إذا صلى الْمُسَافِر خلف إمام مقيم، أتم معه أربع ركعات في الظُّهْر والعصر والعشاء. وإذا صلى الْمُسَافِر إمامًا بمقيمين، فالمأموم المقيم يتم بعد سلام الإمام الْمُسَافِر.'),
    _InfoBox(title: 'متى يبدأ القصر ومتى ينتهي؟', body: 'على قول جمهور الْفُقَهَاء يبدأ بعد مغادرة عمران بلد الإقامة، وينتهي بالعودة إليه أو بانقطاع وصف السَّفَر وفق المدة التي يعتمدها الْمَذْهَب. أحكام المطارات وضواحي المدن قد تحتاج سؤالًا خاصًا.'),
    _InfoBox(title: 'هل يجوز الجمع دون القصر؟', body: 'نعم؛ الجمع والقصر رخصتان مستقلتان، فيمكن أن تجمع وتتم الصَّلَاة أربعًا إذا زال سبب القصر أو كنت خلف مقيم.'),
    _InfoBox(title: 'هل يجوز القصر دون الجمع؟', body: 'نعم؛ يمكن للمسافر أن يقصر الظُّهْر والعصر والعشاء كل صَلَاة في وقتها، وهذا مناسب إذا لم يحتج إلى الجمع.'),
    _InfoBox(title: 'الفرق باختصار', body: 'القصر يغيّر عدد ركعات الصَّلَاة الرباعية من أربع إلى اثنتين. الجمع يغيّر وقت أداء صلاتين. أحدهما لا يستلزم الآخر.'),
  ]);
}

class _ScenarioContent extends StatelessWidget {
  const _ScenarioContent();
  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _InfoBox(title: 'رحلة برية وتوقف وقت الظُّهْر', body: 'إن تحققت صفة السَّفَر وفق القول الذي تتبعه: تصلّي الظُّهْر ركعتين، ولك أن تصلي الْعَصْر ركعتين في وقتها. إن دعت الحاجة، يجوز جمعهما تقديمًا.'),
    _InfoBox(title: 'وصلت إلى مسجد وصليت خلف إمام مقيم', body: 'تابع الإمام وأتم أربع ركعات في الصَّلَاة الرباعية، ولا تنصرف بعد ركعتين.'),
    _InfoBox(title: 'الطائرة تهبط بعد دخول الْعِشَاء', body: 'يمكن للمسافر الذي يحتاج إلى الرخصة أن يجمع الْمَغْرِب والعشاء جمع تأخير عند القدرة على الصَّلَاة بعد النزول، مع مراعاة وقت الصَّلَاة وأحكام الْمَذْهَب.'),
    _InfoBox(title: 'مسافر مرتاح في مكان توقفه', body: 'القصر والجمع حكمان مستقلان؛ يمكنه القصر مع أداء كل صَلَاة في وقتها، ولا يلزمه الجمع لمجرد كونه مسافرًا.'),
  ]);
}

class _QuizContent extends StatelessWidget {
  const _QuizContent({required this.answers, required this.onAnswer, required this.onComplete, required this.completed, required this.onRetake});
  final List<int> answers;
  final Future<void> Function(int, int) onAnswer;
  final Future<void> Function() onComplete;
  final bool completed;
  final Future<void> Function() onRetake;
  static const questions = <(String, List<String>, int)>[
    ('أي صَلَاة تُقصر في السفر؟', ['الْمَغْرِب', 'الْعَصْر', 'الْفَجْر'], 1),
    ('ماذا يعني جمع التقديم؟', ['أداء الصلاتين في وقت الأولى', 'قصر كل صَلَاة', 'تأخيرهما إلى الغد'], 0),
    ('هل يلزم الجمع عند القصر؟', ['نعم دائمًا', 'لا، هما حكمان مستقلان', 'فقط في الْفَجْر'], 1),
    ('إذا صلى الْمُسَافِر خلف إمام مقيم، ماذا يفعل؟', ['يسلم بعد ركعتين', 'يتم الصَّلَاة مع الإمام', 'يترك الجماعة'], 1),
  ];
  @override
  Widget build(BuildContext context) {
    final score = List.generate(questions.length, (i) => i < answers.length && answers[i] == questions[i].$3 ? 1 : 0).fold<int>(0, (a, b) => a + b);
    final done = answers.length >= questions.length && !answers.take(questions.length).contains(-1);
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < questions.length; i++) ...[
        Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(children: [
                CircleAvatar(radius: 13, backgroundColor: colors.primary, child: Text(_arabicDigits(i + 1), style: TextStyle(color: colors.onPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(width: 9),
                Expanded(child: Text(questions[i].$1, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: colors.onPrimaryContainer))),
              ]),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 8, 7),
              child: Column(children: [
                for (var j = 0; j < questions[i].$2.length; j++) RadioListTile<int>(contentPadding: EdgeInsets.zero, dense: true, visualDensity: VisualDensity.compact, horizontalTitleGap: 4, minLeadingWidth: 0, value: j, groupValue: i < answers.length ? answers[i] : -1, onChanged: (v) { if (v != null) onAnswer(i, v); }, title: Text(questions[i].$2[j])),
              ]),
            ),
          ]),
        ),
      ],
      if (completed) ...[
        _InfoBox(title: 'نتيجتك: ${_arabicDigits(score)} من ${_arabicDigits(questions.length)}', body: score == questions.length ? 'أحسنت! إجاباتك كلها صحيحة.' : 'يمكنك مراجعة الدروس والمحاولة مرة أخرى؛ إجاباتك محفوظة.'),
        const SizedBox(height: 16),
      ],
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: done && !completed ? onComplete : null, icon: Icon(completed ? Icons.check_circle : Icons.task_alt), label: Text(completed ? 'تم إكمال الاختبار' : 'إكمال الاختبار')),
      if (completed) ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: onRetake, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة الاختبار')),
      ],
    ]);
  }
}

class _SourcesCard extends StatelessWidget {
  const _SourcesCard();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('المصادر', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), for (final source in TravelPrayerContent.sources) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: SelectableText('• ${source.$1}\n${source.$2}', style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)))])));
}
