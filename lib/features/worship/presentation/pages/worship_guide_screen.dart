import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';

import '../../data/repositories/worship_learning_repository.dart';
import '../../data/worship_illustration_assets.dart';
import '../../data/worship_lesson_content.dart';
import '../../data/worship_ui_strings.dart';
import '../../domain/entities/worship_step.dart';
import '../widgets/worship_lesson_widgets.dart';
import '../widgets/quiz_intro_dialog.dart';
import 'prayer_quiz_screen.dart';
import 'wudu_quiz_screen.dart';

class WorshipGuideScreen extends StatefulWidget {
  const WorshipGuideScreen({super.key, required this.lesson});

  final String lesson;

  @override
  State<WorshipGuideScreen> createState() => _WorshipGuideScreenState();
}

class _WorshipGuideScreenState extends State<WorshipGuideScreen> {
  final _repository = WorshipLearningRepository();
  final _scrollController = ScrollController();
  final Map<String, int> _indices = {'wudu': 0, 'prayer': 0};
  final Set<String> _completed = {};

  String get _lesson => widget.lesson;
  bool _loading = true;

  List<WorshipStep> get _steps =>
      _lesson == 'wudu'
          ? WorshipLessonContent.wudu
          : WorshipLessonContent.prayer;

  int get _index => _indices[_lesson] ?? 0;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final saved = await Future.wait([
      _repository.progress('wudu'),
      _repository.progress('prayer'),
      _repository.isComplete('wudu'),
      _repository.isComplete('prayer'),
    ]);
    if (!mounted) return;
    setState(() {
      _indices['wudu'] = (saved[0] as int).clamp(
        0,
        WorshipLessonContent.wudu.length - 1,
      );
      _indices['prayer'] = (saved[1] as int).clamp(
        0,
        WorshipLessonContent.prayer.length - 1,
      );
      if (saved[2] == true) _completed.add('wudu');
      if (saved[3] == true) _completed.add('prayer');
      _loading = false;
    });
  }

  Future<void> _goToStep(int index) async {
    final next = index.clamp(0, _steps.length - 1);
    setState(() => _indices[_lesson] = next);
    await _repository.saveProgress(_lesson, next);
  }

  Future<void> _next() async {
    if (_index < _steps.length - 1) {
      await _goToStep(_index + 1);
    } else {
      final wasCompleted = _completed.contains(_lesson);
      setState(() => _completed.add(_lesson));
      await _repository.setComplete(_lesson, true);
      if (!_lessonHasQuiz || wasCompleted || !mounted) return;
      {
        final startQuiz = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => QuizIntroDialog(isWudu: _lesson == 'wudu'),
        );
        if (startQuiz == true && mounted) _openLessonQuiz();
      }
    }
  }

  void _openPrayerQuiz() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PrayerQuizScreen()),
    );
  }

  bool get _lessonHasQuiz => _lesson == 'wudu' || _lesson == 'prayer';

  void _openLessonQuiz() {
    if (_lesson == 'wudu') {
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const WuduQuizScreen()));
    } else {
      _openPrayerQuiz();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isWudu = _lesson == 'wudu';
    final step = _steps[_index];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(isWudu ? WorshipUiStrings.wuduLessonTitle : WorshipUiStrings.prayerLessonTitle)),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 32),
                  children: [
                    _HeroCard(
                      isWudu: isWudu,
                      onStart:
                          () => _scrollController.animateTo(
                            230,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isWudu
                                ? WorshipUiStrings.wuduPageHeading
                                : WorshipUiStrings.prayerPageHeading,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (_completed.contains(_lesson))
                          Icon(Icons.task_alt_rounded, color: colors.primary),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isWudu
                          ? WorshipUiStrings.wuduPageDescription
                          : WorshipUiStrings.prayerPageDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    if (!isWudu) ...[
                      const SizedBox(height: 14),
                      const WorshipSectionCard(
                        title: WorshipUiStrings.prayerPreparationTitle,
                        icon: Icons.checklist_rounded,
                        items: WorshipUiStrings.prayerPreparationItems,
                      ),
                    ],
                    if (isWudu) ...[
                      const SizedBox(height: 14),
                      const WorshipSectionCard(
                        title: WorshipUiStrings.wuduPillarsTitle,
                        icon: Icons.menu_book_rounded,
                        intro:
                            WorshipUiStrings.wuduPillarsIntro,
                        items: WorshipUiStrings.wuduPillarsItems,
                      ),
                    ],
                    const SizedBox(height: 14),
                    WorshipStepCard(
                      step: step,
                      index: _index,
                      total: _steps.length,
                      assetPath:
                          isWudu
                              ? WorshipIllustrationAssets.wuduStep(_index)
                              : WorshipIllustrationAssets.prayerStep(_index),
                    ),
                    const SizedBox(height: 12),
                    _StepPicker(
                      steps: _steps,
                      selectedIndex: _index,
                      onSelect: _goToStep,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _index == 0
                                    ? null
                                    : () => _goToStep(_index - 1),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text(WorshipUiStrings.previous),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                _index == _steps.length - 1 &&
                                        _lessonHasQuiz &&
                                        _completed.contains(_lesson)
                                    ? _openLessonQuiz
                                    : _next,
                            iconAlignment: IconAlignment.end,
                            label: Text(
                              _index == _steps.length - 1
                                  ? (_lessonHasQuiz &&
                                          _completed.contains(_lesson)
                                      ? WorshipUiStrings.prayerQuizTitle
                                      : _completed.contains(_lesson)
                                          ? WorshipUiStrings.lessonCompleted
                                          : WorshipUiStrings.completeLesson)
                                  : WorshipUiStrings.next,
                            ),
                            icon: Icon(
                              _index == _steps.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_completed.contains(_lesson)) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.celebration_rounded,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                WorshipUiStrings.completedMessage,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    if (isWudu) ...[
                      const WorshipSectionCard(
                        title: WorshipUiStrings.wuduSunnahTitle,
                        icon: Icons.auto_awesome_outlined,
                        items: WorshipLessonContent.wuduSunnah,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isWudu)
                      const WorshipSectionCard(
                        title: WorshipUiStrings.wuduMistakesTitle,
                        icon: Icons.error_outline_rounded,
                        items: WorshipLessonContent.wuduMistakes,
                      ),
                    if (!isWudu) ...[
                      const SizedBox(height: 12),
                      const WorshipSectionCard(
                        title: WorshipUiStrings.prayerMistakesTitle,
                        icon: Icons.error_outline_rounded,
                        items: WorshipLessonContent.prayerMistakes,
                      ),
                      const SizedBox(height: 12),
                      const _PrayerRakahReferenceCard(),
                      const SizedBox(height: 12),
                      const WorshipSectionCard(
                        title: WorshipUiStrings.prayerSunnahTitle,
                        icon: Icons.auto_awesome_outlined,
                        items: WorshipUiStrings.prayerSunnahItems,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const WorshipSectionCard(
                      title: WorshipUiStrings.referenceTitle,
                      icon: Icons.menu_book_rounded,
                      intro:
                            WorshipUiStrings.referenceIntro,
                      items: WorshipLessonContent.references,
                    ),
                  ],
                ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isWudu, required this.onStart});

  final bool isWudu;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.primary, colors.primary.withValues(alpha: .80)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: colors.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWudu ? WorshipUiStrings.wuduHeroTitle : WorshipUiStrings.prayerHeroTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isWudu
                      ? WorshipUiStrings.wuduHeroSubtitle
                      : WorshipUiStrings.prayerHeroSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: .86),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onStart,
            tooltip: WorshipUiStrings.startLearning,
            icon: Icon(
              Icons.play_circle_fill_rounded,
              color: colors.onPrimary,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPicker extends StatelessWidget {
  const _StepPicker({
    required this.steps,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<WorshipStep> steps;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: steps.length,
      separatorBuilder: (_, index) => const SizedBox(width: 7),
      itemBuilder: (context, index) {
        final active = index == selectedIndex;
        return ChoiceChip(
          label: Text(toArabicIndicDigits(index + 1)),
          selected: active,
          showCheckmark: false,
          onSelected: (_) => onSelect(index),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w800,
            color:
                active
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
          ),
          selectedColor: Theme.of(context).colorScheme.primary,
          shape: const StadiumBorder(),
        );
      },
    ),
  );
}

class _PrayerRakahReferenceCard extends StatelessWidget {
  const _PrayerRakahReferenceCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const rows = [
      (WorshipUiStrings.fajr, '٢', '٢', '—'),
      (WorshipUiStrings.dhuhr, '٤', '٤', '٢'),
      (WorshipUiStrings.asr, '٤', '—', '—'),
      (WorshipUiStrings.maghrib, '٣', '—', '٢'),
      (WorshipUiStrings.isha, '٤', '—', '٢'),
    ];

    Widget cell(String text, {bool emphasized = false}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            fontSize: (textTheme.bodySmall?.fontSize ?? 12) + 1.5,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            color: emphasized ? colors.primary : colors.onSurface,
          ),
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    WorshipUiStrings.prayerRakahCountTitle,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                children: [
                  Row(
                    children: [
                      cell('الصَّلَاة', emphasized: true),
                      cell(WorshipUiStrings.fardLabel, emphasized: true),
                      cell(WorshipUiStrings.sunnahBeforeLabel, emphasized: true),
                      cell(WorshipUiStrings.sunnahAfterLabel, emphasized: true),
                    ],
                  ),
                  Divider(height: 1, color: colors.outlineVariant),
                  for (var i = 0; i < rows.length; i++) ...[
                    Row(
                      children: [
                        cell(rows[i].$1, emphasized: true),
                        cell(rows[i].$2),
                        cell(rows[i].$3),
                        cell(rows[i].$4),
                      ],
                    ),
                    if (i < rows.length - 1)
                      Divider(height: 1, color: colors.outlineVariant),
                  ],
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
